class Item < ActiveRecord::Base
  include UniqueNonDeleted
  # attr_accessible :name, :recommended_selling_price, :category_id
  has_many :stock_entry 
  
  belongs_to :item_category 
  has_one :stock_migration
   
  validates_presence_of :name , :item_category_id , :supplier_code, :customer_code
  
  validate :unique_non_deleted_name
  
  def unique_object
    "item "
  end 
   
  
  def self.active_objects
    Item.where(:is_deleted => false).order("created_at DESC")
  end
=begin
  INITIAL MIGRATION 
=end 
  def has_past_migration?
    StockMigration.where(:item_id => self.id ).count > 0 
  end
  
  def self.create_by_employee(  employee, object_params) 
    return nil if employee.nil? 
    
    new_object = Item.new  
    
    new_object.creator_id                = employee.id 
    new_object.name                      = object_params[:name] 
    new_object.item_category_id          = object_params[:item_category_id]   
    new_object.supplier_code = object_params[:supplier_code]
    new_object.customer_code = object_params[:customer_code]

    new_object.save 
    return new_object 
  end
  
  def  update_by_employee(  employee,   object_params)  
    return nil if employee.nil? 
    
    self.creator_id                = employee.id 
    self.name                      = object_params[:name] 
    self.item_category_id          = object_params[:item_category_id]   
    self.supplier_code = object_params[:supplier_code]
    self.customer_code = object_params[:customer_code]
    self.save 
    return self 
  end
  
  
  def add_stock_and_recalculate_average_cost_post_stock_entry_addition( new_stock_entry )  
    total_amount = ( self.average_cost * self.ready)   + 
                   ( new_stock_entry.base_price_per_piece * new_stock_entry.quantity ) 
                  
    total_quantity = self.ready + new_stock_entry.quantity 
    
    if total_quantity == 0 
      self.average_cost = BigDecimal('0')
    else
      self.average_cost = total_amount / total_quantity .to_f
    end
    self.ready = total_quantity 
    self.save 
    
  end
  
  def delete(current_user)
    return nil if current_user.nil? 
    
    self.is_deleted = true
    self.save 
  end
  
 
=begin
  BECAUSE OF SALES
=end
  def deduct_ready_quantity( quantity)
    self.ready -= quantity 
    self.save
  end
  
  def add_ready_quantity( quantity ) 
    self.ready += quantity 
    self.save
  end
  
=begin
  BECAUSE OF SCRAP -> SCRAP EXCHANGE
=end
  
  def deduct_scrap_quantity( quantity )
    self.scrap -= quantity 
    self.ready += quantity 
    self.save
  end
  
  def add_scrap_quantity( quantity ) 
    self.scrap += quantity 
    self.ready -= quantity 
    self.save 
  end
  
end
