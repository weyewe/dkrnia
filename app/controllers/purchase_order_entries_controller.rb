class PurchaseOrderEntriesController < ApplicationController
  before_filter :role_required, :except => [:search_purchase_order_entry]
  def new
    @parent = PurchaseOrder.find_by_id params[:purchase_order_id]
    @objects = @parent.active_purchase_order_entries 
    @new_object = PurchaseOrderEntry.new
    
    add_breadcrumb "PurchaseOrder", 'new_purchase_order_url'
    set_breadcrumb_for @parent, 'new_purchase_order_purchase_order_entry_url' + "(#{@parent.id})", 
                "Tambah Sales Item ke Sales Order"
  end
  
  def create
    # HARD CODE.. just for testing purposes 
    # params[:customer][:town_id] = Town.first.id 
    @parent = PurchaseOrder.find_by_id params[:purchase_order_id]
    @object = PurchaseOrderEntry.create_by_employee( current_user, @parent, params[:purchase_order_entry] ) 
    if @object.errors.size == 0 
      @new_object=  PurchaseOrderEntry.new
    else
      @new_object= @object
    end
  end
  
  def edit
    # @customer = Customer.find_by_id params[:id] 
    @object = PurchaseOrderEntry.find_by_id params[:id]
  end
  
  def update 
    @object = PurchaseOrderEntry.find_by_id params[:id] 
    @parent = @object.purchase_order
    @object.update_by_employee(current_user,   params[:purchase_order_entry])
    @has_no_errors  = @object.errors.size  == 0
  end
 
  
  
  def destroy
    @object = PurchaseOrderEntry.find_by_id params[:object_to_destroy_id]
    @object.delete(current_user)
  end
  
  
  
  
  
  def search_purchase_order_entry
    search_params = params[:q]
    
    @objects = [] 
    query = '%' + search_params + '%'
    # on PostGre SQL, it is ignoring lower case or upper case 
    @objects = PurchaseOrderEntry.joins(:purchase_order => [:vendor]).where{ (code =~ query)  &
                      (is_deleted.eq false) & 
                      (is_confirmed.eq true) }.map do |x| 
                        {
                          :code => x.code, 
                          :id => x.id, 
                          :vendor_name => x.purchase_order.vendor.name 
                        }
                      end
    
    respond_to do |format|
      format.html # show.html.erb 
      format.json { render :json => @objects }
    end
  end
end
