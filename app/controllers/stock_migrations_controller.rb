class StockMigrationsController < ApplicationController
  def new
    @new_object = StockMigration.new 
  end
  
  # only the view 
  def generate_stock_migration
    # @new_object = StockMigration.new 
    @item_id =  params[:selected_item_id] 
    @item = Item.find_by_id @item_id
    
    @new_object = StockMigration.find_by_item_id(@item.id) || StockMigration.new
    
  end
  
  def create 
    @item = Item.find_by_id params[:item_id]  
    
    params[:stock_migration][:item_id] = params[:item_id]
    # @object = StockMigration.create_item_migration(current_user , item, params[:stock_migration])
    @object =   StockMigration.create_by_employee(current_user, params[:stock_migration])  
    @item.reload 
    
    
    if @object.errors.size !=  0 
      @new_object=  StockMigration.new 
    else
      @new_object= @object
    end 
  end
  
  def update
    @object = StockMigration.find_by_id params[:id] 
    @item = @object.item 
    @object.update_by_employee( current_user, params[:item])
    @has_no_errors  = @object.errors.messages.length == 0
  end
  
  
  def update
    @item = Item.find_by_id params[:item_id]  
    params[:stock_migration][:item_id] = params[:item_id]
    @object = StockMigration.find_by_id params[:id]
    @object.update_by_employee(current_user, params[:stock_migration])  
    @item.reload 
    @has_no_errors = @object.errors.size == 0 
    
    
  end
  
  
  
end
