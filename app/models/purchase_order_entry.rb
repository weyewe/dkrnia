=begin
  Pending: if it is possible, don't allow the completed receival to be received 
  or not even being shown 
=end

class PurchaseOrderEntry < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :purchase_order
  belongs_to :item 
  belongs_to :vendor 
  has_many :purchase_receival_entries 
    
  
  validates_presence_of :item_id  
  validates_presence_of :creator_id
  validates_presence_of :quantity  
  
   
  # validate :quantity_must_not_less_than_zero 
  
  after_save :update_item_pending_receival, :update_fulfillment_status
  after_destroy :update_item_pending_receival 
  
  # this is called when there is change in the purchase_receival_entry#purchase_order_entry
  # or the purchase_order_entry 's quantity is changed 
  def update_fulfillment_status
    if self.is_confirmed? 
      fulfilled = self.purchase_receival_entries.where(:is_confirmed => true).sum("quantity")
      if fulfilled >= self.quantity
        self.is_fulfilled = true 
        self.save 
      end
    end
  end
  
  def update_item_pending_receival
    item = self.item 
    item.reload 
    item.update_pending_receival
  end
     
  def quantity_must_not_less_than_zero
    if quantity.present? and quantity <= 0 
      msg = "Kuantitas  tidak boleh 0 atau negative "
      errors.add(:quantity_for_production , msg )
    end
  end
     
  def delete(employee)
    return nil if employee.nil?
    # if self.is_confirmed?   
    #   ActiveRecord::Base.transaction do
    #     self.post_confirm_delete( employee )  
    #     return self
    #   end
    # end
    
    self.destroy 
  end
  
  def post_confirm_delete( employee)  
    # if there has been receival, can't be destroyed. 
    self.purchase_receival_entries.each do |x|
      x.delete( employee )  
    end
    
    self.destroy 
  end
  
  
  
  def self.create_by_employee( employee, purchase_order, params ) 
    return nil if employee.nil?
    return nil if purchase_order.nil? 
    
    new_object = self.new
    new_object.creator_id = employee.id 
    new_object.purchase_order_id = purchase_order.id 
    
    new_object.quantity           = params[:quantity]       
    new_object.item_id     = params[:item_id]     
    
    if new_object.save 
      new_object.generate_code 
    end
    
    return new_object 
  end
  
  def update_by_employee( employee, params ) 
    # if self.is_confirmed? 
    #   ActiveRecord::Base.transaction do
    #     self.post_confirm_update( employee, params) 
    #     return self  
    #   end
    # end
    
    self.quantity    = params[:quantity]       
    self.item_id     = params[:item_id]
           
    self.save 
    
    return self 
  end
  
  
  def post_confirm_update(employee, params)
    # if item is changed  
    # if quantity is changed 
  end
  
  
  def generate_code
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
    
    string = "#{header}POE" + 
              ( self.created_at.year%1000).to_s + "-" + 
              ( self.created_at.month).to_s + '-' + 
              ( counter.to_s ) 
              
    
    self.code =  string 
    self.save 
  end
   
  def confirm
    return nil if self.is_confirmed == true 
    self.is_confirmed = true 
    self.save
    self.generate_code
    self.reload 
  end
  
  def received_quantity 
    self.purchase_receival_entries.where(:is_confirmed => true).sum('quantity')
  end
  
  def pending_receival
    self.quantity - self.received_quantity 
  end
  
end