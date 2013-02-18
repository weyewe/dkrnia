class VendorsController < ApplicationController
  before_filter :role_required, :except => [:search_vendor]
  def new
    @objects = Vendor.active_objects
    @new_object = Vendor.new 
  end
  
  def create
    # HARD CODE.. just for testing purposes 
    # params[:vendor][:town_id] = Town.first.id 
    @object = Vendor.create( params[:vendor] ) 
    if @object.valid?
      @new_object=  Vendor.new
    else
      @new_object= @object
    end
    
  end
  
  def search_vendor
    search_params = params[:q]
    
    @objects = [] 
    query = '%' + search_params + '%'
    # on PostGre SQL, it is ignoring lower case or upper case 
    @objects = Vendor.where{ (name =~ query)  & (is_deleted.eq false) }.map{|x| {:name => x.name, :id => x.id }}
    
    respond_to do |format|
      format.html # show.html.erb 
      format.json { render :json => @objects }
    end
  end
  
  def edit
    @object = Vendor.find_by_id params[:id] 
  end
  
  def update
    @object = Vendor.find_by_id params[:id] 
    
    @object.update_attributes( params[:vendor])
    @has_no_errors  = @object.errors.messages.length == 0
  end
  
  def destroy
    @object = Vendor.find_by_id params[:id]
    @object.delete(current_user )
  end
end

