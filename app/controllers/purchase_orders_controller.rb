class PurchaseOrdersController < ApplicationController
  before_filter :role_required
  def new
    @objects = PurchaseOrder.active_objects 
    @new_object = PurchaseOrder.new 
    
    add_breadcrumb "Purchase Order", 'new_purchase_order_url'
  end
  
  def create
    # HARD CODE.. just for testing purposes 
    # params[:customer][:town_id] = Town.first.id 
    
    @object = PurchaseOrder.create_by_employee( current_user, params[:purchase_order] ) 
    if @object.errors.size == 0 
      @new_object=  PurchaseOrder.new
    else
      @new_object= @object
    end
    
  end
  
   
  
  def edit
    # @customer = Customer.find_by_id params[:id] 
    @object = PurchaseOrder.find_by_id params[:id]
  end
  
  def update 
    @object = PurchaseOrder.find_by_id params[:id] 
    @object.update_by_employee( current_user, params[:purchase_order])
    @has_no_errors  = @object.errors.size  == 0
  end
  
  def destroy
    @object = PurchaseOrder.find_by_id params[:object_to_destroy_id]
    @object.delete(current_user) 
  end
  
=begin
  CONFIRM SALES RELATED
=end
  def confirm_purchase_order
    @purchase_order = PurchaseOrder.find_by_id params[:purchase_order_id]
    # add some defensive programming.. current user has role admin, and current_user is indeed belongs to the company 
    @purchase_order.confirm( current_user  )  
  end
  
  
=begin
  DETAILS
=end
  def details
    puts "We are in the details of sales order\n"*50
    @object = PurchaseOrder.find_by_id params[:id]
  end
  
  def search_purchase_order
    search_params = params[:q]
    
    @objects = [] 
    query = '%' + search_params + '%'
    # on PostGre SQL, it is ignoring lower case or upper case 
    @objects = PurchaseOrder.where{ (code =~ query)  &
                      (is_deleted.eq false) & 
                      (is_confirmed.eq true) }.map do |x| 
                        {
                          :code => x.code, 
                          :id => x.id 
                        }
                      end
    
    respond_to do |format|
      format.html # show.html.erb 
      format.json { render :json => @objects }
    end
  end
  
  def generate_details 
    @parent = PurchaseOrder.find_by_id params[:purchase_order][:search_record_id]
    @children = @parent.purchase_order_entries.order("created_at DESC") 
  end
  
=begin
  PRINT SALES ORDER
=end
  # def print_purchase_order
  #   @purchase_order = PurchaseOrder.find_by_id params[:purchase_order_id]
  #   respond_to do |format|
  #     format.html # do
  #      #        pdf = SalesInvoicePdf.new(@purchase_order, view_context)
  #      #        send_data pdf.render, filename:
  #      #        "#{@purchase_order.printed_sales_invoice_code}.pdf",
  #      #        type: "application/pdf"
  #      #      end
  #     format.pdf do
  #       pdf = PurchaseOrderPdf.new(@purchase_order, view_context,CONTINUOUS_FORM_WIDTH,FULL_CONTINUOUS_FORM_LENGTH)
  #       send_data pdf.render, filename:
  #       "#{@purchase_order.printed_sales_invoice_code}.pdf",
  #       type: "application/pdf"
  #     end
  #   end
  # end
end
