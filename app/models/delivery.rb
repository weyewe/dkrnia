class Delivery < ActiveRecord::Base
  include StockMutationDocument
  # attr_accessible :title, :body
  validates_presence_of :creator_id
  validates_presence_of :employee_id 
    
  has_many :delivery_entries 
  belongs_to :employee 
  
   
   
  def self.active_objects
    self.where(:is_deleted => false ).order("created_at DESC")
  end
  
  def delete(employee) 
    return nil if employee.nil? 
    if self.is_confirmed? 
      # ActiveRecord::Base.transaction do
      #   self.post_confirm_delete( employee) 
      # end
      # return self
    end
   
    self.destroy
  end
  
  def post_confirm_delete( employee) 
     
    if self.delivery_entries.count != 0 
      self.errors.add(:generic_error , "Sudah ada pengiriman." )  
      return self
    end
    
     
    self.delivery_entries.each do |si|
      si.delete( employee ) 
    end 
    
    self.is_deleted = true 
    self.save 
  end
  
   
  
  
  def active_delivery_entries 
    self.delivery_entries.where(:is_deleted => false ).order("created_at DESC")
  end
  
  def update_by_employee( employee, params ) 
    if self.is_confirmed?
      return self
    end
    self.employee_id = params[:employee_id]
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
    new_object.employee_id = params[:employee_id]
    new_object.delivery_date = params[:delivery_date]
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
    
    
    string = "#{header}DL" + "/" + 
              self.created_at.year.to_s + '/' + 
              self.created_at.month.to_s + '/' + 
              counter.to_s
              
    self.code =  string 
    self.save 
  end
   
  
  def confirm(employee) 
    return nil if employee.nil? 
    return nil if self.active_delivery_entries.count == 0 
    return nil if self.is_confirmed == true  
    
    # transaction block to confirm all the sales item  + sales receival confirmation 
    ActiveRecord::Base.transaction do
      self.confirmer_id = employee.id 
      self.confirmed_at = DateTime.now 
      self.is_confirmed = true 
      self.save 
      self.generate_code
      self.delivery_entries.each do |de|
        de.confirm 
      end
    end 
  end
  
  
  def finalize(employee)
    return nil if employee.nil? 
    return nil if self.is_confirmed == false 
    return nil if self.is_finalized == true  
    
    # transaction block to confirm all the sales item  + sales order confirmation 

    ActiveRecord::Base.transaction do
      self.finalizer_id = employee.id 
      self.finalized_at = DateTime.now 
      self.is_finalized = true 
      self.save 
      
      
      if  self.errors.size != 0  
        raise ActiveRecord::Rollback, "Call tech support!" 
        # puts "Fuck, errors.size!= 0"
        return self
      end

      self.reload 
      self.delivery_entries.each do |delivery_entry|
        delivery_entry.finalize 
      end
    
    end 
  end
  
  
=begin
  Sales Invoice Printing
=end
  def printed_code
    self.code.gsub('/','-')
  end

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
