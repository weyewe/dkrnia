class StockMutation < ActiveRecord::Base
  # attr_accessible :title, :body
  attr_accessible :quantity, :stock_entry_id, :source_document_entry_id, 
                  :creator_id, :source_document_id, :source_document_entry,
                  :source_document, :deduction_case,
                  :mutation_case, :mutation_status,
                  :item_id, :item_status,
                  :scrap_item_id
                  
  belongs_to :item
  after_save :update_item_statistics
   

  def update_item_statistics
    item.update_ready_quantity
  end
  
  
  def StockMutation.generate_stock_migration_stock_mutation( stock_migration )
    new_object = StockMutation.new 
    
    new_object.creator_id               = stock_migration.creator_id
    
    new_object.quantity                 = stock_migration.quantity
    
    new_object.source_document_entry_id = stock_migration.id    
    new_object.source_document_id       = stock_migration.id 
    new_object.source_document_entry    = stock_migration.class.to_s
    new_object.source_document          = stock_migration.class.to_s
    new_object.item_id                  = stock_migration.item_id
    new_object.mutation_case            = MUTATION_CASE[:stock_migration] 
    new_object.mutation_status          = MUTATION_STATUS[:addition]  
    
    new_object.save 
  end
  
  def update_stock_migration_stock_mutation(stock_migration)
    return nil if stock_migration.quantity == self.quantity 
    
    self.quantity = stock_migration.quantity 
    self.save 
  end
  
  def StockMutation.create_stock_adjustment( employee, stock_adjustment)
    item = stock_adjustment.item 
    if stock_adjustment.adjustment_case == STOCK_ADJUSTMENT_CASE[:addition]
      
      new_stock_entry = StockEntry.new 
      new_stock_entry.creator_id = employee.id
      new_stock_entry.quantity = stock_adjustment.adjustment_quantity
      new_stock_entry.base_price_per_piece  = item.average_cost 
      new_stock_entry.item_id  = item.id  
      new_stock_entry.entry_case =  STOCK_ENTRY_CASE[:stock_adjustment]
      new_stock_entry.source_document = stock_adjustment.class.to_s
      new_stock_entry.source_document_id = stock_adjustment.id  
      new_stock_entry.save 
      
      
      item.add_stock_and_recalculate_average_cost_post_stock_entry_addition( new_stock_entry ) 
    
      # create the StockMutation
      StockMutation.create(
        :quantity            => stock_adjustment.adjustment_quantity  ,
        :stock_entry_id      =>  new_stock_entry.id ,
        :creator_id          =>  employee.id ,
        :source_document_entry_id  =>  stock_adjustment.id   ,
        :source_document_id  =>  stock_adjustment.id  ,
        :source_document_entry     =>  stock_adjustment.class.to_s,
        :source_document    =>  stock_adjustment.class.to_s,
        :mutation_case      => MUTATION_CASE[:stock_adjustment],
        :mutation_status => MUTATION_STATUS[:addition],
        :item_id => item.id
      ) 
    else stock_adjustment.adjustment_case == STOCK_ADJUSTMENT_CASE[:deduction]
      
      
                
                
      requested_quantity =  stock_adjustment.adjustment_quantity
      # and for price deduction? 
      # over here, we have assumption that for a given stock entry, it is enough to be deducted.
      # that is not the case though. 
      # the deduction might come from several stock entries. 
      StockMutation.deduct_ready_stock(
              employee, 
              requested_quantity, 
              item, 
              stock_adjustment, 
              stock_adjustment,
              MUTATION_CASE[:stock_adjustment], 
              MUTATION_STATUS[:deduction]  
            )
             
      
    end
  end
  
  
  def StockMutation.generate_purchase_receival_stock_mutation( purchase_receival_entry  ) 
    new_object = StockMutation.new 
    
    new_object.creator_id               = purchase_receival_entry.purchase_receival.creator_id
    new_object.quantity                 = purchase_receival_entry.quantity
    new_object.source_document_entry_id = purchase_receival_entry.id 
    new_object.source_document_id       = purchase_receival_entry.purchase_receival_id
    new_object.source_document_entry    = purchase_receival_entry.class.to_s
    new_object.source_document          = purchase_receival_entry.purchase_receival.class.to_s
    new_object.item_id                  = purchase_receival_entry.purchase_order_entry.item_id 
    new_object.mutation_case            = MUTATION_CASE[:purchase_receival] 
    new_object.mutation_status          = MUTATION_STATUS[:addition]  
    
    new_object.save
  end
  
  def purchase_receival_change_item( purchase_receival_entry ) 
    self.quantity = purchase_receival_entry.quantity
    self.item_id = purchase_receival_entry.purchase_order_entry.item_id 
    self.save 
  end
  
   
  def StockMutation.create_mutation_by_stock_conversion( object_params)
    new_object = StockMutation.new 
    
    new_object.creator_id               = object_params[:creator_id]
    
    new_object.quantity                 = object_params[:quantity]
    new_object.stock_entry_id           = object_params[:stock_entry_id] 
    
    new_object.source_document_entry_id = object_params[:source_document_entry_id]     
    new_object.source_document_id       = object_params[:source_document_id]     
    new_object.source_document_entry    = object_params[:source_document_entry]  
    new_object.source_document          = object_params[:source_document]   
    new_object.item_id                  = object_params[:item_id]   
    new_object.mutation_case            = MUTATION_CASE[:stock_conversion_target] 
    new_object.mutation_status          = MUTATION_STATUS[:addition]  
    
    new_object.save 
  end
  
=begin
  Generic ready stock deduction 
=end
  def StockMutation.deduct_ready_stock(
          employee, 
          quantity, 
          item, 
          source_document, 
          source_document_entry,
          mutation_case, 
          mutation_status  
        )
        
      requested_quantity =  quantity
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

        StockMutation.create(
          :quantity            => served_quantity  ,
          :stock_entry_id      =>  stock_entry.id ,
          :creator_id          =>  employee.id ,
          :source_document_entry_id  =>  source_document_entry.id  ,
          :source_document_id  =>  source_document.id  ,
          :source_document_entry     =>  source_document_entry.class.to_s,
          :source_document    =>  source_document.class.to_s,
          :mutation_case      => mutation_case,
          :mutation_status => mutation_status,
          :item_id => stock_entry.item_id ,
          :item_status => ITEM_STATUS[:ready]
        )

      end
  end
  
  
end



