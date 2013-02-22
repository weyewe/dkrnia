class PurchaseReceival < ActiveRecord::Base
  include StockMutationDocument
  # attr_accessible :title, :body
  validates_presence_of :creator_id
  validates_presence_of :vendor_id  
  has_many :purchase_receival_entries 
  
  belongs_to :vendor 
  
   
   
  def self.active_objects
    self.where(:is_deleted => false ).order("created_at DESC")
  end
  
  def delete(employee) 
    return nil if employee.nil? 
    if self.is_confirmed? 
      # ActiveRecord::Base.transaction do
      #   self.post_confirm_delete( employee) 
      # end
      return self
    end
   
    self.destroy
  end
  
  # def post_confirm_delete( employee) 
  #   
  #   # if one of its child is delivered, can't delete 
  #   # wtf.. just delete.
  #   
  #   sales_item_id_list = self.sales_items.map{|x| x.id }
  #   if DeliveryEntry.where(:sales_item_id => sales_item_id_list).count != 0 
  #     self.errors.add(:delete_fail , "Sudah ada pengiriman." )  
  #     return self
  #   end
  #   
  #    
  #   self.sales_items.each do |si|
  #     si.delete( employee ) 
  #   end 
  #   
  #   self.is_deleted = true 
  #   self.save 
  # end
  
   
  
  
  def active_purchase_receival_entries 
    self.purchase_receival_entries.where(:is_deleted => false ).order("created_at DESC")
  end
  
  def update_by_employee( employee, params ) 
    if self.is_confirmed?
      return self
    end
    self.vendor_id = params[:vendor_id]
    self.save
    return self 
  end
  
  
=begin
  BASIC
=end
  def self.create_by_employee( employee, params ) 
    return nil if employee.nil? 
    
    new_object = self.new
    new_object.creator_id = employee.id
    new_object.vendor_id = params[:vendor_id]
    
    # today_date_time = DateTime.now 
    # 
    # new_object.receival_date   = 
    
    if new_object.save
      new_object.generate_code
    end
    
    return new_object 
  end
  
  def generate_code
    # get the total number of sales receival created in that month 
    
    # total_sales_receival = SalesOrder.where()
    start_datetime = Date.today.at_beginning_of_month.to_datetime
    end_datetime = Date.today.next_month.at_beginning_of_month.to_datetime
    
    counter = self.class.where{
      (self.created_at >= start_datetime)  & 
      (self.created_at < end_datetime )
    }.count
    
    if self.is_confirmed?
      counter = self.class.where{
        (self.created_at >= start_datetime)  & 
        (self.created_at < end_datetime ) & 
        (self.is_confirmed.eq true )
      }.count
    end
    
  
    header = ""
    if not self.is_confirmed?  
      header = "[pending]"
    end
    
    
    string = "#{header}PRC" + "/" + 
              self.created_at.year.to_s + '/' + 
              self.created_at.month.to_s + '/' + 
              counter.to_s
              
    self.code =  string 
    self.save 
  end
   
  
  def confirm(employee) 
    return nil if employee.nil? 
    return nil if self.active_purchase_receival_entries.count == 0 
    return nil if self.is_confirmed == true  
    
    # transaction block to confirm all the sales item  + sales receival confirmation 
    ActiveRecord::Base.transaction do
      self.confirmer_id = employee.id 
      self.confirmed_at = DateTime.now 
      self.is_confirmed = true 
      self.save 
      self.generate_code
      self.purchase_receival_entries.each do |po_entry|
        po_entry.confirm 
      end
    end 
  end
  
  
  
=begin
  Sales Invoice Printing
=end
  def printed_sales_invoice_code
    self.code.gsub('/','-')
  end

  def calculated_vat
    BigDecimal("0")
  end

  def calculated_delivery_charges
    BigDecimal("0")
  end

  def calculated_sales_tax
    BigDecimal('0')
  end
end
