class StockMigration < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :item
  
  
  validate :only_one_stock_migration_per_item
  
  
  def only_one_stock_migration_per_item
    if self.persisted? and   
            StockMigration.where(:item_id => self.item_id).count != 1 
      errors.add(:item_id , "Tidak boleh ada stock migration ganda" )  
    end
  end
  
  
  def stock_entry 
    stock_migration = self 
    StockEntry.find(:first, :conditions => {
      :source_document => stock_migration.class.to_s, 
      :source_document_id => stock_migration.id ,
      :entry_case =>  STOCK_ENTRY_CASE[:initial_migration], 
      :is_addition => true 
    })
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
  
  def StockMigration.create_by_employee(employee, item, object_params)
    return nil if employee.nil?
    
    new_object              = StockMigration.new 
    new_object.creator_id   = employee.id 
    new_object.item_id      = item.id 
    
    new_object.quantity     = object_params[:quantity]
    new_object.average_cost = object_params[:average_cost]
     
    if new_object.save  
      new_object.generate_code
    end 
    
  
    
    return new_object 
  end
  
  def  update_by_employee(employee,   object_params)
    return nil if employee.nil?
    
    self.creator_id = employee.id 
     
    self.quantity     = object_params[:quantity]
    self.average_cost = object_params[:average_cost] 
    self.save   
    
    return self 
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
      StockEntry.generate_stock_migration_stock_entry( self  ) 
    end
    
  end
  
  
    
  
  
end
