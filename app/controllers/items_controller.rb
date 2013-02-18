class ItemsController < ApplicationController
  def new
    @objects = Item.active_objects
    @new_object = Item.new 
    
    respond_to do |format|
      format.html # show.html.erb 
      format.js 
    end
  end
  
  def create 
    @parent = ItemCategory.find_by_id params[:item][:item_category_id]
    
    @object = Item.create_by_employee(  current_user,  params[:item])
    
    
    if @object.valid?
      @new_object=  Item.new
    else
      @new_object= @object
    end 
    
    respond_to do |format|
      format.html { render :file => 'items/new' }
      format.js 
    end
    
  end
  
  def search_item
    
    # verify the current_user 
    search_params = params[:q]
    
    @items = [] 
    item_query = '%' + search_params + '%'
    # on PostGre SQL, it is ignoring lower case or upper case 
    @items = Item.where{ (name =~ item_query)  & (is_deleted.eq false ) }.map{|x| {:name => x.name, :id => x.id }}
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @post }
      format.json { render :json => @items }
    end 
  end
  
  def search_sales_order_item
    search_params = params[:q]
    @sales_order = SalesOrder.find_by_id params[:sales_order_id]
    query = '%' + search_params + '%'
    # on PostGre SQL, it is ignoring lower case or upper case 
    # @objects = Item.where(
    #              :id => @sales_order.item_id_list ,
    #              :is_deleted => false 
    #            ).map{|x| {:name => x.name, :id => x.id }}
    #          
    item_id_list =    @sales_order.item_id_list 
    @objects = Item.where{
          ( is_deleted.eq false) & 
          (id.in item_id_list ) & 
          (name =~ query) 
    }.map{|x| {:name => x.name, :id => x.id }} 
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @post }
      format.json { render :json => @objects }
    end
    
  end
  
  
  def edit
    @object = Item.find_by_id params[:id] 
  end
  
  def update
    @object = Item.find_by_id params[:id] 
    @object.update_by_employee( current_user, params[:item])
    @has_no_errors  = @object.errors.messages.length == 0
  end
  
  def destroy
    @object = Item.find_by_id params[:object_to_destroy_id]
    @object.delete(current_user)
  end
  
  
  
end
