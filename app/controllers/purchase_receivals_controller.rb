class PurchaseReceivalsController < ApplicationController
  before_filter :role_required
  def new
    @objects = PurchaseReceival.active_objects 
    @new_object = PurchaseReceival.new 
    
    add_breadcrumb "Purchase Receival", 'new_purchase_receival_url'
  end
  
  def create
    # HARD CODE.. just for testing purposes 
    # params[:customer][:town_id] = Town.first.id 
    
    @object = PurchaseReceival.create_by_employee( current_user, params[:purchase_receival] ) 
    if @object.errors.size == 0 
      @new_object=  PurchaseReceival.new
    else
      @new_object= @object
    end
    
  end
  
   
  
  def edit
    # @customer = Customer.find_by_id params[:id] 
    @object = PurchaseReceival.find_by_id params[:id]
  end
  
  def update 
    @object = PurchaseReceival.find_by_id params[:id] 
    @object.update_by_employee( current_user, params[:purchase_receival])
    @has_no_errors  = @object.errors.size  == 0
  end
  
  def destroy
    @object = PurchaseReceival.find_by_id params[:object_to_destroy_id]
    @object.delete(current_user) 
  end
  
=begin
  CONFIRM SALES RELATED
=end
  def confirm_purchase_receival
    @purchase_receival = PurchaseReceival.find_by_id params[:purchase_receival_id]
    # add some defensive programming.. current user has role admin, and current_user is indeed belongs to the company 
    @purchase_receival.confirm( current_user  )  
  end
  
  
=begin
  DETAILS
=end
  def details
    puts "We are in the details of sales order\n"*50
    @object = PurchaseReceival.find_by_id params[:id]
  end
  
  def search_purchase_receival
    search_params = params[:q]
    
    @objects = [] 
    query = '%' + search_params + '%'
    # on PostGre SQL, it is ignoring lower case or upper case 
    @objects = PurchaseReceival.where{ (code =~ query)  &
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
    @parent = PurchaseReceival.find_by_id params[:purchase_receival][:search_record_id]
    @children = @parent.purchase_receival_entries.order("created_at DESC") 
  end
  
=begin
  PRINT SALES ORDER
=end
  # def print_purchase_receival
  #   @purchase_receival = PurchaseReceival.find_by_id params[:purchase_receival_id]
  #   respond_to do |format|
  #     format.html # do
  #      #        pdf = SalesInvoicePdf.new(@purchase_receival, view_context)
  #      #        send_data pdf.render, filename:
  #      #        "#{@purchase_receival.printed_sales_invoice_code}.pdf",
  #      #        type: "application/pdf"
  #      #      end
  #     format.pdf do
  #       pdf = PurchaseReceivalPdf.new(@purchase_receival, view_context,CONTINUOUS_FORM_WIDTH,FULL_CONTINUOUS_FORM_LENGTH)
  #       send_data pdf.render, filename:
  #       "#{@purchase_receival.printed_sales_invoice_code}.pdf",
  #       type: "application/pdf"
  #     end
  #   end
  # end
end
