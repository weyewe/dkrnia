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
  
  
  def StockMutation.create_mutation_by_stock_migration( object_params)
    new_object = StockMutation.new 
    
    new_object.creator_id               = object_params[:creator_id]
    
    new_object.quantity                 = object_params[:quantity]
    new_object.stock_entry_id           = object_params[:stock_entry_id] 
    
    new_object.source_document_entry_id = object_params[:source_document_entry_id]     
    new_object.source_document_id       = object_params[:source_document_id]     
    new_object.source_document_entry    = object_params[:source_document_entry]  
    new_object.source_document          = object_params[:source_document]   
    new_object.item_id                  = object_params[:item_id]   
    new_object.mutation_case            = MUTATION_CASE[:stock_migration] 
    new_object.mutation_status          = MUTATION_STATUS[:addition]  
    
    new_object.save 
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
  
  
  def StockMutation.create_mutation_by_purchase_receival( object_params)
    new_object = StockMutation.new 
    
    new_object.creator_id               = object_params[:creator_id]
    
    new_object.quantity                 = object_params[:quantity]
    new_object.stock_entry_id           = object_params[:stock_entry_id] 
    
    new_object.source_document_entry_id = object_params[:source_document_entry_id]     
    new_object.source_document_id       = object_params[:source_document_id]     
    new_object.source_document_entry    = object_params[:source_document_entry]  
    new_object.source_document          = object_params[:source_document]   
    new_object.item_id                  = object_params[:item_id]   
    new_object.mutation_case            = MUTATION_CASE[:purchase_receival] 
    new_object.mutation_status          = MUTATION_STATUS[:addition]  
    
    new_object.save 
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



