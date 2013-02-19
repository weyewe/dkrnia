class PurchaseReceivalEntriesController < ApplicationController
  before_filter :role_required, :except => [:search_purchase_receival_entry]
  def new
    @parent = PurchaseReceival.find_by_id params[:purchase_receival_id]
    @objects = @parent.active_purchase_receival_entries 
    @new_object = PurchaseReceivalEntry.new
    
    add_breadcrumb "PurchaseReceival", 'new_purchase_receival_url'
    set_breadcrumb_for @parent, 'new_purchase_receival_purchase_receival_entry_url' + "(#{@parent.id})", 
                "Tambah  Item ke Purchase Receival "
  end
  
  def create
    # HARD CODE.. just for testing purposes 
    # params[:customer][:town_id] = Town.first.id 
    @parent = PurchaseReceival.find_by_id params[:purchase_receival_id]
    @object = PurchaseReceivalEntry.create_by_employee( current_user, @parent, params[:purchase_receival_entry] ) 
    if @object.errors.size == 0 
      @new_object=  PurchaseReceivalEntry.new
    else
      @new_object= @object
    end
  end
  
  def edit
    # @customer = Customer.find_by_id params[:id] 
    @object = PurchaseReceivalEntry.find_by_id params[:id]
  end
  
  def update 
    @object = PurchaseReceivalEntry.find_by_id params[:id] 
    @parent = @object.purchase_receival
    @object.update_by_employee(current_user,   params[:purchase_receival_entry])
    @has_no_errors  = @object.errors.size  == 0
  end
 
  
  
  def destroy
    @object = PurchaseReceivalEntry.find_by_id params[:object_to_destroy_id]
    @object.delete(current_user)
  end
  
  
  
  
  
  def search_purchase_receival_entry
    search_params = params[:q]
    
    @objects = [] 
    query = '%' + search_params + '%'
    # on PostGre SQL, it is ignoring lower case or upper case 
    @objects = PurchaseReceivalEntry.joins(:purchase_receival => [:vendor]).where{ (code =~ query)  &
                      (is_deleted.eq false) & 
                      (is_confirmed.eq true) }.map do |x| 
                        {
                          :code => x.code, 
                          :id => x.id, 
                          :vendor_name => x.purchase_receival.vendor.name 
                        }
                      end
    
    respond_to do |format|
      format.html # show.html.erb 
      format.json { render :json => @objects }
    end
  end
end
