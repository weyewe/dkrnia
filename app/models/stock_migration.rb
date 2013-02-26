class StockMigration < ActiveRecord::Base
  include StockMutationDocument
  include StockMutationDocumentEntry 
  include StockEntryDocument
  include StockEntryDocumentEntry
  # attr_accessible :title, :body
  belongs_to :item
  validates_presence_of :quantity 
  validate :quantity_not_zero
  validate :only_one_stock_migration_per_item
  
  def quantity_not_zero
    if quantity.present? and quantity <=   0   
      errors.add(:quantity , "Tidak lebih kecil dari 0" )  
    end
  end
  
  def only_one_stock_migration_per_item
    if self.persisted? and   
        StockMigration.where(:item_id => self.item_id).count != 1 
      errors.add(:item_id , "Tidak boleh ada stock migration ganda" )  
    end
  end
  
  
   
  
  def generate_code
    # get the total number of sales order created in that month 
    
    # total_sales_order = SalesOrder.where()
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
    
    
    string = "#{header}SMG" + "/" + 
              self.created_at.year.to_s + '/' + 
              self.created_at.month.to_s + '/' + 
              counter.to_s
              
    self.code =  string 
    self.save 
  end
  
  def StockMigration.create_by_employee(employee,  params)
    return nil if employee.nil?
    
    new_object              = StockMigration.new 
    new_object.creator_id   = employee.id 
    new_object.item_id      = params[:item_id]
    
    new_object.quantity     = params[:quantity]
     
    ActiveRecord::Base.transaction do
      if new_object.save  
        new_object.generate_code
        # and auto confirm 
        new_object.confirm(employee)
      end 
    end
    
  
    
    return new_object 
  end
  
  def  update_by_employee(employee,   object_params)
    return nil if employee.nil?
    
    self.creator_id = employee.id 
     
    initial_quantity = self.quantity 
    self.quantity     = object_params[:quantity]
    
    # guard.. if there is error, won't go through
    ActiveRecord::Base.transaction do
      if self.save   
        # stock_entry.update_stock_migration_stock_entry( self ) if not stock_entry.nil? 
        stock_mutation.update_stock_migration_stock_mutation( self ) if not stock_mutation.nil? 
      end
    end
    
    return self 
  end
  
  def stock_entry 
    StockEntry.where(
      :source_document => self.class.to_s, 
      :source_document_id => self.id 
    ).first 
  end
  
  def confirm( employee ) 
    return nil if self.is_confirmed?   
    
    # transaction block to confirm all the sales item  + sales order confirmation 
    ActiveRecord::Base.transaction do
      self.confirmer_id = employee.id 
      self.confirmed_at = DateTime.now 
      self.is_confirmed = true 
      self.save 
      self.generate_code
      
      # create the Stock Entry  + Stock Mutation =>  Update Ready Item 
      # StockEntry.generate_stock_migration_stock_entry( self  ) 
      StockMutation.generate_stock_migration_stock_mutation(self ) 
      # item = self.item  
      # item.add_stock_and_recalculate_average_cost_post_stock_entry_addition 
    end
    
  end
  
  
    
  
  
end
