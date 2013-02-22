=begin
  StockEntry => used to track FIFO price. Nothing to do with inventory
=end
class StockEntry < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :item
  has_many :stock_mutations 
  has_many :stock_entry_usages
  
  def available_quantity  
    quantity - used_quantity  - scrapped_quantity
  end
  
  def self.first_available_stock(item) 
    # FOR FIFO , we will devour the first available item
    StockEntry.where(:is_finished => false, :item_id => item.id ).order("id ASC").first 
  end
  
=begin
  Adding stock entry during stock migration 
=end 
  def self.generate_stock_migration_stock_entry( stock_migration  ) 
    new_object                      = StockEntry.new 
    new_object.creator_id           = stock_migration.creator_id
    new_object.quantity             = stock_migration.quantity 
    # new_object.base_price_per_piece = stock_migration.average_cost 
    new_object.item_id              = stock_migration.item_id 
    new_object.entry_case           = STOCK_ENTRY_CASE[:stock_migration]
    new_object.source_document      = stock_migration.class.to_s
    new_object.source_document_id   = stock_migration.id 
    new_object.save  
  end
  
  def update_stock_migration_stock_entry(stock_migration)
    return nil if stock_migration.quantity == self.quantity 
      
    if stock_migration.quantity > self.quantity 
      # expansion case
      self.quantity = stock_migration.quantity 
      self.is_finished = false
      self.save 
    else
      # contraction case
      
      if stock_migration.quantity > self.used_quantity 
        self.is_finished = false   
        self.quantity = stock_migration.quantity 
        self.save
      elsif stock_migration.quantity == self.used_quantity 
        self.is_finished = true 
        self.quantity = stock_migration.quantity 
        self.save
      elsif stock_migration.quantity < self.used_quantity
        dispatchable_quantity = self.used_quantity - stock_migration.quantity 
        self.is_finished = true 
        self.quantity = stock_migration.quantity 
        self.save
        
        StockEntry.dispatch_usage( self, dispatchable_quantity )  
      end
    end
  end
  
  def self.dispatch_usage( stock_entry, dispatchable_quantity )
    stock_entry_usages = stock_entry.stock_entry_usages.order("created_at DESC")
    
    dispatched_quantity = 0 
    stock_entry.stock_entry_usages.order("created_at DESC").each do |stock_entry_usage| 
      if dispatchable_quantity > 0  &&  stock_entry_usage.quantity <=  dispatchable_quantity 
        stock_entry_usage.assign_stock_entry  
        dispatchable_quantity -= stock_entry_usage.quantity
      elsif dispatchable_quantity > 0  &&  stock_entry_usage.quantity > dispatchable_quantity 
        stock_entry_usage.assign_partial_stock_entry( dispatchable_quantity)
        dispatchable_quantity -= dispatchable_quantity
      end
      
      break if dispatchable_quantity == 0 
    end 
  end
  
  
  
=begin
  ADDING STOCK_ENTRY after purchase receival
=end

  def self.generate_purchase_receival_stock_entry( purchase_receival_entry  ) 
    new_object                      = StockEntry.new 
    new_object.creator_id           = purchase_receival_entry.creator_id
    new_object.quantity             = purchase_receival_entry.quantity 
    # new_object.base_price_per_piece = stock_migration.average_cost 
    new_object.item_id              = purchase_receival_entry.purchase_order_entry.item_id 
    new_object.entry_case           = STOCK_ENTRY_CASE[:purchase_receival]
    new_object.source_document      = purchase_receival_entry.class.to_s
    new_object.source_document_id   = purchase_receival_entry.id 
    new_object.save  
  
  end
  
  def purchase_receival_change_item(purchase_receival_entry)
    self.quantity                = purchase_receival_entry.quantity 
    self.item_id                 = purchase_receival_entry.purchase_order_entry.item_id 
    self.is_finished             = false 
    self.used_quantity           = 0
    self.scrapped_quantity       = 0 
    self.save 
  end
  
  
  # if the quantity has been used. 
  # final quantity < initial quantity 
    # get the excess usage to 2 stock mutations 
  # if final quantity > initial quantity 
    # create excess usage to stock mutations 
  def update_purchase_receival_stock_entry(purchase_receival_entry)
    self.quantity = stock_migration.quantity 
    self.save 
    
    stock_mutation = StockMutation.where(
      :stock_entry_id => self.id , 
      :source_document_entry_id => stock_migration.id,
      :source_document_entry => stock_migration.class.to_s 
    ).first 
    stock_mutation.quantity = self.quantity 
    stock_mutation.save 
  end
  
  
=begin
  Adding stock entry because of stock conversion
=end 
  def self.generate_stock_conversion_stock_entry( stock_conversion , stock_converter_entry_target ) 
    item = stock_converter_entry_target.item 
    base_price_per_piece = ?? #? find the stock mutations used to deduct the source (stock entries)
    # and sum it up 50,000*5 + 40,000*4  << if it came from 2 stock entries 
    
    base_price_per_piece = base_price_per_piece/stock_converter_entry_target.quantity.to_f
    
    new_object                      = StockEntry.new 
    new_object.creator_id           = stock_conversion.creator_id
    new_object.quantity             = stock_converter_entry_target.quantity 
    new_object.base_price_per_piece = stock_conversion.average_cost 
    new_object.item_id              = stock_conversion.item_id 
    new_object.entry_case           = STOCK_ENTRY_CASE[:stock_migration]
    new_object.source_document      = stock_conversion.class.to_s
    new_object.source_document_id   = stock_conversion.id 
    new_object.save  

    item = stock_conversion.item  

    item.add_stock_and_recalculate_average_cost_post_stock_entry_addition( new_object ) 

    StockMutation.create_mutation_by_stock_migration(  {
      :creator_id               =>  stock_migration.creator_id   ,
      :quantity                 => stock_migration.quantity      ,
      :stock_entry_id           => new_object.id                 ,
      :source_document_entry_id => stock_migration.id            ,
      :source_document_id       => stock_migration.id            ,
      :source_document_entry    => stock_migration.class.to_s    ,
      :source_document          => stock_migration.class.to_s    ,
      :item_id                  => item.id
    }) 
  end
  
=begin
  Adding StockEntry because of InstantPurchase 
=end


  
  # used in stock entry deduction 
  def update_usage(served_quantity) 
    self.used_quantity += served_quantity    
    self.save  
    
    self.mark_as_finished
    
    item = self.item 
    item.deduct_ready_quantity(served_quantity ) 
    
    return self  
  end
  
  
  #  used in sales return =>  recovering the ready item, from the sold 
  def recover_usage(quantity_to_be_recovered)
    self.used_quantity -= quantity_to_be_recovered 
    self.save  
     
    self.unmark_as_finished
    
    
    
    item = self.item 
    item.add_ready_quantity( quantity_to_be_recovered ) 
    
    return self 
  end

  def self.first_available_stock(item) 
    # FOR FIFO , we will devour the first available item
    StockEntry.where(:is_finished => false, :item_id => item.id ).order("id ASC").first 
  end
  
  def stock_migration
    if self.entry_case == STOCK_ENTRY_CASE[:stock_migration]
      StockMigration.find_by_id self.source_document_id
    else
      return nil
    end
  end
  
  
  # MAYBE WE DON't NEED THIS SHIT? since we have the squeel 
  def mark_as_finished 
    if self.used_quantity + self.scrapped_quantity == self.quantity
      self.is_finished = true 
    end
    self.save
  end
  
  def unmark_as_finished 
    if self.used_quantity + self.scrapped_quantity < self.quantity
      self.is_finished = false 
    end
    self.save
  end
  
  
=begin
  SCRAP RELATED : READY -> SCRAP
=end 

  def perform_item_scrapping( served_quantity) 
    self.scrapped_quantity += served_quantity  
    self.save 
    
    self.mark_as_finished 
    
    item.add_scrap_quantity( served_quantity )  
    
    return self
  end
  
=begin
  SCRAP EXCHANGE RELATED : SCRAP -> READY
=end

  def perform_scrap_item_replacement( scrap_recover_quantity) 
    self.scrapped_quantity -= scrap_recover_quantity  
    self.save 
  
    self.unmark_as_finished  
  
    item.deduct_scrap_quantity( scrap_recover_quantity )  
  
    return self
  end
  
end
