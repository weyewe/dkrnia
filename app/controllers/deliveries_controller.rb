class DeliveriesController < ApplicationController
  before_filter :role_required
  def new
    @objects = Delivery.order("created_at DESC")
    @new_object = Delivery.new 
    add_breadcrumb "Surat Jalan", 'new_delivery_url'
  end
  
  def create
    # HARD CODE.. just for testing purposes 
    # params[:customer][:town_id] = Town.first.id 
    
    @object = Delivery.create_by_employee( current_user, params[:delivery] ) 
    if @object.errors.size == 0 
      @new_object=  Delivery.new
    else
      @new_object= @object
    end
    
  end
  
  
  
  def edit
    # @customer = Customer.find_by_id params[:id] 
    @object = Delivery.find_by_id params[:id]
  end
  
  def update
    @object = Delivery.find_by_id params[:id] 
    @object.update_by_employee( current_user, params[:delivery])
    @has_no_errors  = @object.errors.size  == 0
  end
  
  def destroy 
    @object = Delivery.find_by_id params[:object_to_destroy_id]
    @object_identifier = @object.code 
    @object.delete(current_user) 
  end
  
=begin
  CONFIRM SALES RELATED
=end
  def confirm_delivery
    @delivery = Delivery.find_by_id params[:delivery_id]
    # add some defensive programming.. current user has role admin, and current_user is indeed belongs to the company 
    @delivery.confirm( current_user  )  
    @delivery.reload
  end
  
  def finalize_delivery
    @delivery = Delivery.find_by_id params[:delivery_id]
    # add some defensive programming.. current user has role admin, and current_user is indeed belongs to the company
    # sleep 3 
    @delivery.finalize( current_user  )
    @delivery.reload
  end
  
=begin
  DETAILS
=end
  def details
    puts "We are in the details of sales order\n"*50
    @object = Delivery.find_by_id params[:id]
  end

  def search_delivery
    search_params = params[:q]

    @objects = [] 
    query = '%' + search_params + '%'
    # on PostGre SQL, it is ignoring lower case or upper case 
    @objects = Delivery.where{ (code =~ query)  &
                      (is_deleted.eq false) & 
                      (is_confirmed.eq true) & 
                      (is_finalized.eq true) }.map do |x| 
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
    @parent = Delivery.find_by_id params[:delivery][:search_record_id]
    @children = @parent.delivery_entries.order("created_at DESC") 
  end
  
=begin
  PRINT SALES ORDER
=end
  def print_delivery
    @delivery = Delivery.find_by_id params[:delivery_id]
    respond_to do |format|
      format.html # do
       #        pdf = SalesInvoicePdf.new(@sales_order, view_context)
       #        send_data pdf.render, filename:
       #        "#{@sales_order.printed_sales_invoice_code}.pdf",
       #        type: "application/pdf"
       #      end
      format.pdf do
        pdf = DeliveryOrderPdf.new(@delivery, view_context,CONTINUOUS_FORM_WIDTH,FULL_CONTINUOUS_FORM_LENGTH)
        send_data pdf.render, filename:
        "#{@delivery.printed_code}.pdf",
        type: "application/pdf"
      end
    end
  end
end
