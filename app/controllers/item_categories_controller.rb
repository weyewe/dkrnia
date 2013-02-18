class ItemCategoriesController < ApplicationController
  def new
    @objects = ItemCategory.active_objects
    @new_item_category = ItemCategory.new 
    @new_object = @new_item_category
    
    respond_to do |format|
      format.html # show.html.erb 
      format.js 
    end
  end
  
  def create
    # base_item_category = ItemCategory.find_by_id params[:item_category][:parent_id]
    
    # sleep 5
    
    @object = ItemCategory.create_by_employee(current_user,  params[:item_category] ) 
    if @object.valid?
      @new_object=  ItemCategory.new
    else
      @new_object= @object
    end
    
  end
  
  def edit
    @object = ItemCategory.find_by_id params[:id] 
  end
  
  def update 
    @object = ItemCategory.find_by_id params[:id] 
    @object.update_by_employee( current_user, params[:item_category])
    @has_no_errors  = @object.errors.messages.length == 0
  end
  
  def destroy
    @object = ItemCategory.find_by_id params[:id]
    @object.delete(current_user )
  end
  
end
