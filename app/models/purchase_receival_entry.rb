class PurchaseReceivalEntry < ActiveRecord::Base
  include StockMutationDocumentEntry
  include StockEntryDocumentEntry
  # attr_accessible :title, :body
  belongs_to :purchase_receival
  belongs_to :purchase_order_entry
  belongs_to :item 
  belongs_to :vendor 
    
  
  validates_presence_of :item_id  
  validates_presence_of :creator_id
  validates_presence_of :quantity  
  validates_presence_of :purchase_order_entry_id 
  has_many :purchase_receival_entries
  
   
  validate :quantity_must_not_less_than_zero 
  validate :quantity_must_not_exceed_the_ordered_quantity
  validate :unique_purchase_order_entry 
  
  after_save :update_item_pending_receival, :update_purchase_order_entry_fulfilment_status, :update_item_statistics
  after_destroy :update_item_pending_receival , :update_purchase_order_entry_fulfilment_status, :update_item_statistics
  
  def update_item_pending_receival
    puts "inside the update item pending receival"
    return nil if not self.is_confirmed? 
    puts "Gonna execute update item pending receival"
    item = self.item 
    item.reload 
    item.update_pending_receival
  end
  
  def update_item_statistics
    return nil if not self.is_confirmed? 
    item = self.item 
    item.reload
    item.update_ready_quantity
  end
  
  def update_purchase_order_entry_fulfilment_status
    purchase_order_entry = self.purchase_order_entry 
    purchase_order_entry.reload 
    purchase_order_entry.update_fulfillment_status
    # what if they change the purchase_order_entry
  end
     
  def quantity_must_not_less_than_zero
    if quantity.present? and quantity <= 0 
      msg = "Kuantitas  tidak boleh 0 atau negative "
      errors.add(:quantity_for_production , msg )
    end
  end
     
  def quantity_must_not_exceed_the_ordered_quantity
    return nil if self.purchase_order_entry.nil? 
    return nil if self.is_confirmed? 
    
    purchase_order_entry = self.purchase_order_entry 
    received_quantity = purchase_order_entry.received_quantity
    ordered_quantity = purchase_order_entry.quantity 
    pending_receival = ordered_quantity - received_quantity
    
    if  self.quantity > pending_receival 
      errors.add(:quantity , "Max penerimaan untuk item dari purchase order ini: #{pending_receival}" )
    end
  end   
  
  def unique_purchase_order_entry
    purchase_order_entry = self.purchase_order_entry 
    return nil if purchase_order_entry.nil? 
    
    parent = self.purchase_receival 
    purchase_receival_entry_count = PurchaseReceivalEntry.where(
      :purchase_order_entry_id => self.purchase_order_entry_id,
      :purchase_receival_id => parent.id  
    ).count 
    
    item = purchase_order_entry.item 
    purchase_order = purchase_order_entry.purchase_order
    msg = "Item #{item.name} dari pemesanan #{purchase_order.code} sudah terdaftar di penerimaan ini"
 
    if not self.persisted? and purchase_receival_entry_count != 0
      errors.add(:purchase_order_entry_id , msg ) 
    elsif self.persisted? and purchase_receival_entry_count > 1 
      errors.add(:purchase_order_entry_id , msg ) 
    end
  end
     
  def delete(employee)
    return nil if employee.nil?
    if self.is_confirmed?  
      ActiveRecord::Base.transaction do
        self.post_confirm_delete( employee)  
        return self
      end 
    end
    
    
    self.destroy 
  end
  
  def post_confirm_delete( employee)  
    StockMutation.where(
      :source_document_entry_id => self.id,
      :source_document_entry => self.class.to_s
    ).each {|x| x.destroy }
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
      ActiveRecord::Base.transaction do
        self.post_confirm_update( employee, params) 
        return self
      end 
    end

    purchase_order_entry = PurchaseOrderEntry.find_by_id params[:purchase_order_entry_id]    
    self.purchase_order_entry_id = purchase_order_entry.id 
    self.quantity                = params[:quantity]       
    self.item_id                 = purchase_order_entry.item_id
 
    self.save 
    return self 
  end
  
  def post_confirm_update(employee, params)
    
    purchase_order_entry = PurchaseOrderEntry.find_by_id params[:purchase_order_entry_id]
    old_purchase_order_entry = self.purchase_order_entry
    
    is_item_changed = false
    is_quantity_changed = false
    
    
    if params[:purchase_order_id] != self.purchase_order_entry_id
      is_item_changed = true 
    end
    
    if params[:purchase_order_id] == self.purchase_order_entry_id and 
        params[:quantity] != self.quantity
      is_quantity_changed = true 
    end
    
    if  is_item_changed
      self.purchase_order_entry_id = params[:purchase_order_entry_id]
      self.item_id                 = purchase_order_entry.item_id
      self.quantity                = params[:quantity]
      purchase_receival_entry_count = PurchaseReceivalEntry.where(
        :purchase_order_entry_id => self.purchase_order_entry_id,
        :purchase_receival_id => self.purchase_receival.id  
      ).count

      self.save 
    end
    
    if is_quantity_changed
      self.quantity                = params[:quantity]
      self.save
    end
    
    
    stock_mutation.purchase_receival_change_item( self )  if not self.stock_mutation.nil?
    
    if purchase_order_entry.id != old_purchase_order_entry.id 
      old_purchase_order_entry.reload 
      old_purchase_order_entry.update_fulfillment_status
    end
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
    
    # create  stock_entry and the associated stock mutation 
    # StockEntry.generate_purchase_receival_stock_entry( self  ) 
    StockMutation.generate_purchase_receival_stock_mutation( self  ) 
  end
  
end
