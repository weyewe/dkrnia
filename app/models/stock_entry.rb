=begin
  StockEntry => used to track FIFO price. Nothing to do with inventory
=end
class StockEntry < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :item
  has_many :stock_mutations 
  
  
  
 
  
  def available_quantity  
    quantity - used_quantity 
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
    new_object.entry_case           = STOCK_ENTRY_CASE[:initial_migration]
    new_object.source_document      = stock_migration.class.to_s
    new_object.source_document_id   = stock_migration.id 
    new_object.save  
    
    item = stock_migration.item  
    
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
  
  def update_stock_migration_stock_entry(stock_migration)
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
    new_object.entry_case           = STOCK_ENTRY_CASE[:initial_migration]
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
    if self.entry_case == STOCK_ENTRY_CASE[:initial_migration]
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
