class PurchaseReceivalEntry < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :purchase_receival
  belongs_to :purchase_order_entry
  belongs_to :item 
  belongs_to :vendor 
    
  
  validates_presence_of :item_id  
  validates_presence_of :creator_id
  validates_presence_of :quantity  
  validates_presence_of :purchase_order_entry_id 
  
   
  validate :quantity_must_not_less_than_zero 
  
  after_save :update_item_pending_receival
  after_destroy :update_item_pending_receival 
  
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
    if self.is_confirmed?  
      # do something. if it is linked to payment.. we need to do something
      # if it is not linked.. no need 
    end
    
    self.destroy 
  end
  
  def post_confirm_delete( employee)  
    self.destroy 
  end
  
  
  
  def self.create_by_employee( employee, purchase_receival, params ) 
    return nil if employee.nil?
    return nil if purchase_receival.nil? 
    purchase_order_entry = PurchaseOrderEntry.find_by_id params[:purchase_order_entry_id]
    
    
    new_object = self.new
    new_object.creator_id = employee.id 
    new_object.vendor_id = purchase_receival.vendor_id 
    
    new_object.purchase_receival_id = purchase_receival.id 
    new_object.purchase_order_entry_id = purchase_order_entry.id 
    new_object.quantity                = params[:quantity]       
    new_object.item_id                 = purchase_order_entry.item_id   
    
    if new_object.save 
      new_object.generate_code 
    end
    
    return new_object 
  end
  
  def update_by_employee( employee, params ) 
    if self.is_confirmed? 
      # later on, put authorization 
    end

    purchase_order_entry = PurchaseOrderEntry.find_by_id params[:purchase_order_entry_id]

    self.purchase_order_entry_id = purchase_order_entry.id 
    self.quantity                = params[:quantity]       
    self.item_id                 = purchase_order_entry.item_id


    self.save 

    return self 
  end
  
  
  # def post_confirm_update(employee, params)
  # end
  
  
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
    
    string = "#{header}PRCE" + 
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
    self.reload 
  end
  
end