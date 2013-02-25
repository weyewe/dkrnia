class StockEntryUsage < ActiveRecord::Base
  attr_accessible :stock_entry_id , 
                  :quantity                   ,
                  :source_document_entry_id   ,
                  :source_document_id         ,
                  :source_document_entry      ,
                  :source_document            ,
                  :case                     

  belongs_to :stock_entry
  
  
  def self.generate_delivery_stock_entry_usage( delivery_entry )
    new_object = self.new 
    
    new_object.source_document_entry_id   = delivery_entry.id 
    new_object.source_document_id         = delivery_entry.delivery_id       
    new_object.source_document_entry      = delivery_entry.class.to_s    
    new_object.source_document            = delivery_entry.delivery.class.to_s           
    new_object.case                       = STOCK_ENTRY_USAGE[:delivery]        
    
    new_object.save 
    
    new_object.assign_stock_entry( delivery_entry.item, delivery_entry.quantity_sent )              
  end
  
  def self.generate_stock_adjustment_stock_entry_usage( stock_adjustment )
    item = stock_adjustment.item 
    new_object = self.new 
    
    new_object.source_document_entry_id   = stock_adjustment.id 
    new_object.source_document_id         = stock_adjustment.id       
    new_object.source_document_entry      = stock_adjustment.class.to_s    
    new_object.source_document            = stock_adjustment.class.to_s           
    new_object.case                       = STOCK_ENTRY_USAGE[:stock_adjustment]        
    
    new_object.save 
    
    
    new_object.assign_stock_entry( stock_adjustment.item, stock_adjustment.adjustment_quantity )   
    item.update_ready_quantity            
  end
  
  
  def StockEntryUsage.update_delivery_finalization_stock_entry_usage( delivery_entry )
    return nil if not delivery_entry.delivery.is_finalized
    
    
    quantity_returned = delivery_entry.quantity_returned 
    return nil if quantity_returned == 0 
    
    delivery_entry.stock_entry_usages.order("id DESC").each do |seu| 
      
        recovered_quantity = 0 
        
        if seu.quantity < quantity_returned
          # destroy the stock entry usage, recover_stock_entry 
          recovered_quantity = seu.quantity 
        else
          # just deduct the quantity of stock entry usage + recover stock entry accordingly
          recovered_quantity = quantity_returned 
        end
        
        seu.recover_usage( recovered_quantity ) 
        
        quantity_returned -= recovered_quantity
        break if quantity_returned == 0 
    end
  end 
  
  def recover_usage( recovered_quantity ) 
    self.stock_entry.recover_usage(  recovered_quantity )
    if recovered_quantity == self.quantity 
      self.destroy   
    else
      self.quantity = self.quantity - recovered_quantity
      self.save 
    end
  end
  

  
  
  # create the base stock usage. then, assign stock entry.. Voila! we have our shite! 
  def assign_stock_entry( item , quantity ) 
    # Find the empty stock entry. assign himself
    # if it is not enough, split into multiple stock_entry_usage 
    requested_quantity =   quantity 
    supplied_quantity = 0 
    is_first = true 
    while supplied_quantity != requested_quantity
      unfulfilled_quantity = requested_quantity - supplied_quantity 
      stock_entry =  StockEntry.first_available_stock(  item )
      # what if 1 stock entry quantity is not enough?
      # get it from the next stock entry. However, it means that we need to use 
      #   NEW StockEntryUsage.. recursive call? 

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
      if is_first
        self.stock_entry_id  = stock_entry.id 
        self.quantity = served_quantity
        self.save
        is_first = false 
      else
        StockEntryUsage.create(
          :stock_entry_id  => stock_entry.id , 
          :quantity => served_quantity, 
          :source_document_entry_id => self.source_document_entry_id,
          :source_document_id => self.source_document_id, 
          :source_document_entry => self.source_document_entry,
          :source_document => self.source_document,
          :case => self.case 
        )
      end
      
      supplied_quantity += served_quantity 
    end 
  end
  
=begin
  To update the quantity of stock entry. Rare case, but anyway juts do it. 
=end
  
  def assign_partial_stock_entry( dispatchable_quantity)
    new_object = StockEntryUsage.new 
    new_object.source_document_id       = self.source_document_id      
    new_object.source_document_entry_id = self.source_document_entry_id
    new_object.source_document          = self.source_document         
    new_object.source_document_entry    = self.source_document_entry   
    new_object.stock_entry_id           = self.stock_entry_id 
    
    if new_object.save 
      new_object.assign_stock_entry( stock_entry.item , dispatchable_quantity )
    else
      raise ActiveRecord::Rollback, "Some shit happened. Can't create stock entry usage" 
    end
  end
end
