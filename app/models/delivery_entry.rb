class DeliveryEntry < ActiveRecord::Base
  include StockMutationDocumentEntry
  # attr_accessible :title, :body
  belongs_to :delivery
  belongs_to :item 
  belongs_to :vendor 
    
  
  validates_presence_of :item_id  
  validates_presence_of :creator_id
  validates_presence_of :quantity_sent
   
   
  validate :quantity_must_not_less_than_zero 
  # validate :quantity_must_not_exceed_available_quantity
  validate :unique_item_entry 
  
  after_save  :update_item_statistics
  after_destroy  :update_item_statistics
  
  def update_item_pending_receival
    return nil if not self.is_confirmed? 
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
    purchase_order_entry.update_fulfillment_status
    # what if they change the purchase_order_entry
  end
     
  def quantity_must_not_less_than_zero
    if quantity_sent.present? and quantity_sent <= 0 
      msg = "Kuantitas  tidak boleh 0 atau negative "
      errors.add(:quantity_for_production , msg )
    end
  end
     
  # def quantity_must_not_exceed_available_quantity
  #   return nil if self.purchase_order_entry.nil? 
  #   return nil if self.is_confirmed? 
  #   
  #  
  #   received_quantity = purchase_order_entry.received_quantity
  #   ordered_quantity = purchase_order_entry.quantity 
  #   pending_receival = ordered_quantity - received_quantity
  #   
  #   if  self.quantity > pending_receival 
  #     errors.add(:quantity , "Max penerimaan untuk item dari purchase order ini: #{pending_receival}" )
  #   end
  # end   
  
  def unique_item_entry
    return nil if self.item_id.nil? 
    item = self.item 
    
    parent = self.delivery 
    delivery_entry_count = DeliveryEntry.where(
      :item_id => self.item_id,
      :delivery_id => parent.id  
    ).count 
    
    msg = "Item #{item.name} dari pemesanan #{parent.code} sudah terdaftar di surat jalan ini"
 
    if not self.persisted? and delivery_entry_count != 0
      errors.add(:item_id , msg ) 
    elsif self.persisted? and delivery_entry_count != 1 
      errors.add(:item_id , msg ) 
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
    # if there is stock_usage_entry.. refresh => dispatch to other available shite 
    stock_entry.update_stock_migration_stock_entry( self ) if not stock_entry.nil? 
    stock_mutation.update_stock_migration_stock_mutation( self ) if not stock_mutation.nil?
    
    stock_entry.destroy 
    stock_mutation.destroy 
    self.destroy 
  end
  
  
  
  def self.create_by_employee( employee, delivery, params ) 
    return nil if employee.nil?
    return nil if delivery.nil? 
    
    new_object = self.new
    new_object.creator_id = employee.id 
    
    new_object.delivery_id = delivery.id 
    new_object.quantity_sent                = params[:quantity_sent]       
    new_object.item_id                 = params[:item_id]
    
    if new_object.save 
      new_object.generate_code 
    end
    
    return new_object 
  end
  
  def update_by_employee( employee, params ) 
    if self.is_confirmed? 
      # later on, put authorization 
      self.post_confirm_update( employee, params) 
      return self 
    end

    self.quantity_sent                = params[:quantity_sent]       
    self.item_id                 = params[:item_id]
 
    self.save 
    return self 
  end
  
  # def post_confirm_update(employee, params)
  #   
  #   purchase_order_entry = DeliveryEntry.find_by_id params[:purchase_order_entry_id]
  #   old_purchase_order_entry = self.purchase_order_entry
  #   
  #   
  #   
  #   if params[:purchase_order_entry_id] != self.purchase_order_entry_id
  #     self.purchase_order_entry_id = params[:purchase_order_entry_id]
  #     self.quantity_sent                = 0 
  #     self.item_id                 = purchase_order_entry.item_id
  #     self.save
  #     
  #     # we need to shift the stock_usage_entry from the associated stock entry to somewhere else
  #     # then, after shifting, we can re-point the data 
  #     stock_entry.update_stock_migration_stock_entry( self ) if not stock_entry.nil? 
  #     stock_mutation.update_stock_migration_stock_mutation( self ) if not stock_mutation.nil?
  #     
  #     # use the original quantity 
  #     self.quantity = params[:quantity]
  #     self.save
  #     stock_entry.delivery_change_item( self )
  #     stock_mutation.delivery_change_item( self )  
  #   else
  #     # only changing the quantity 
  #     self.quantity                = params[:quantity]
  #     self.save
  #     
  #     stock_entry.update_stock_migration_stock_entry( self ) if not stock_entry.nil? 
  #     stock_mutation.update_stock_migration_stock_mutation( self ) if not stock_mutation.nil?
  #   end
  #   
  #   if purchase_order_entry.id != old_purchase_order_entry.id 
  #     old_purchase_order_entry.update_fulfillment_status
  #   end
  # end
  # 
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
    
    string = "#{header}DE" + 
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
    StockEntryUsage.generate_delivery_stock_entry_usage( self ) 
    StockMutation.generate_delivery_stock_mutation( self ) 
  end
  
  
=begin
  UPDATE THE DELIVERY RESULT
=end
  def validate_post_delivery_quantity 
    if quantity_confirmed.nil? or quantity_confirmed < 0 
      self.errors.add(:quantity_confirmed , "Tidak boleh kurang dari 0" ) 
    end
    
    if quantity_returned.nil? or quantity_returned < 0 
      self.errors.add(:quantity_returned , "Tidak boleh kurang dari 0" ) 
    end
    
    if quantity_lost.nil? or quantity_lost < 0 
      self.errors.add(:quantity_lost , "Tidak boleh kurang dari 0" ) 
    end
  end
  
  def validate_post_delivery_total_sum
    # puts "\n\nInside validate_post_delivery_total_sum"
    # 
    # puts "quantity_sent : #{self.quantity_sent}"
    # puts "quantity_confirmed : #{ self.quantity_confirmed}"
    # puts "quantity_returned : #{ self.quantity_returned}"
    # puts "quantity_lost : #{ self.quantity_lost} "
    # 
    # puts "3333 done "
    if self.quantity_confirmed + self.quantity_returned + self.quantity_lost != self.quantity_sent 
      msg = "Jumlah yang terkirim: #{self.quantity_sent}. " +
              "Konfirmasi #{self.quantity_confirmed} + " + 
              " Retur #{self.quantity_returned }+ " + 
              " Hilang #{self.quantity_lost} tidak sesuai."
      self.errors.add(:quantity_confirmed , msg ) 
      self.errors.add(:quantity_returned ,  msg ) 
      self.errors.add(:quantity_lost ,      msg ) 
    end
  end
   
  
  
  def validate_post_delivery_update 
    self.validate_post_delivery_quantity 
    self.validate_post_delivery_total_sum   
  end
    
  def update_post_delivery( employee, params ) 
    return nil if employee.nil? 
    # if self.is_finalized?
    #   self.post_finalize_update( employee, params)
    #   return self 
    # end 
    self.quantity_confirmed        = params[:quantity_confirmed]
    self.quantity_returned         = params[:quantity_returned]
    self.quantity_lost             = params[:quantity_lost]
    self.validate_post_delivery_update
    # puts "after validate_post_production_update, errors: #{self.errors.size.to_s}"
    self.errors.messages.each do |message|
      puts "The message: #{message}"
    end
    
    return self if  self.errors.size != 0 
    # puts "Not supposed to be printed out if there is error"
    if self.save  
      puts "9888 we saved this thing successfully"
    end
    return self  
  end
  
  
  def finalize 
    return nil if self.is_confirmed == false 
    return nil if self.is_finalized == true 
     
     
    # puts "BEFORE validate post delivery update" 
    # puts "quantity_sent : #{self.quantity_sent}"
    # puts "quantity_confirmed : #{self.quantity_confirmed}"
    # puts "quantity_returned : #{self.quantity_returned}"
    # puts "quantity_lost : #{self.quantity_lost} "
    
    self.validate_post_delivery_update
    
    if  self.errors.size != 0 
      puts("AAAAAAAAAAAAAAAA THe sibe kia is NOT  valid")
      
      self.errors.messages.each do |key, values| 
        puts "The key is #{key.to_s}"
        values.each do |value|
          puts "\tthe value is #{value}"
        end
      end
      
      raise ActiveRecord::Rollback, "Call tech support!" 
    end
    
    
    
    self.is_finalized = true 
    self.save 
    
    StockMutation.create_delivery_return_stock_mutation( self ) 
    StockMutation.create_delivery_lost_stock_mutation( self ) 
    StockEntryUsage.update_delivery_finalization_stock_entry_usage( self ) 
  end
  
  def stock_entry_usages
    StockEntryUsage.where(
      :source_document_entry_id => self.id,
      :source_document_entry => self.class.to_s ,
      :case => STOCK_ENTRY_USAGE[:delivery]  
    )
  end
   
  def delivery_return_stock_mutation
    StockMutation.where(
      :source_document_entry_id => self.id,
      :source_document_entry => self.class.to_s ,
      :mutation_case => MUTATION_CASE[:delivery_returned],
      :mutation_status => MUTATION_STATUS[:addition]
    ).first 
  end
  
  def delivery_lost_stock_mutation
    StockMutation.where(
      :source_document_entry_id => self.id,
      :source_document_entry => self.class.to_s ,
      :mutation_case => MUTATION_CASE[:delivery_lost],
      :mutation_status => MUTATION_STATUS[:deduction]
    ).first 
  end
  
  
end