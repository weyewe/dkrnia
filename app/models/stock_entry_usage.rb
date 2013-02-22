class StockEntryUsage < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :stock_entry
  
  
  def assign_stock_entry
    # Find the empty stock entry. assign himself
    # if it is not enough, split into multiple stock_entry_usage 
    item = self.stock_entry.item 
    requested_quantity =  self.quantity 
    supplied_quantity = 0 

    while supplied_quantity != requested_quantity
      unfulfilled_quantity = requested_quantity - supplied_quantity 
      stock_entry =  StockEntry.first_available_stock(  item )

      #  stock_entry.nil? raise error  # later.. 
      if stock_entry.nil?
        raise ActiveRecord::Rollback, "Can't be executed. No Item in the stock" 
      end

      available_quantity = stock_entry.available_quantity 

      served_quantity = 0 
      if unfulfilled_quantity <= available_quantity 
        served_quantity = unfulfilled_quantity 
      else
        served_quantity = available_quantity 
      end

      stock_entry.update_usage(served_quantity) 
      supplied_quantity += served_quantity 
    end 
  end
  
  
  def assign_partial_stock_entry( dispatchable_quantity)
    new_object = StockEntryUsage.new 
    new_object.source_document_id       = self.source_document_id      
    new_object.source_document_entry_id = self.source_document_entry_id
    new_object.source_document          = self.source_document         
    new_object.source_document_entry    = self.source_document_entry   
    new_object.stock_entry_id           = self.stock_entry_id 
    new_object.quantity                 = dispatchable_quantity 
    
    if new_object.save 
      new_object.assign_stock_entry
    else
      if stock_entry.nil?
        raise ActiveRecord::Rollback, "Some shit happened. Can't create stock entry usage" 
      end
    end
    
  end
end
