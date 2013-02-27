class DeliveryOrderPdf < Prawn::Document
  
  # def initialize(invoice, view)
  #   super()
  #   @delivery_order = invoice
  #   @view = view
  #   text "Invoice #{@delivery_order.printed_sales_invoice_code}"
  # end
  
  
  
  
  def initialize(delivery_order , view, page_width, page_length)
    super(:page_size =>  [page_width, page_length])  #[width,length]
    @page_width = page_width
    @page_length = page_length
    @delivery_order = delivery_order
    @view = view
    # page_size  [684, 792]
    font("Courier")
    
    # text "My report caption", :size => 18, :align => :right
    # move_down font.height * 2
    
    @company = Company.first
    
    
    # printing the document title 
    title 
    move_down 20 
    
    # printing the company header, and customer header 
    company_customer_details 
    
    # printing the core data: table 
    document_details 
    
    # say thanks or something? => signature
    regards_message
    
    
    page_numbering 
  end
   
   
  def title
    bounding_box( [150,cursor], :width => @page_width - 300) do
      text "Delivery: #{@delivery_order.code}", 
          :size => 15, 
          :align => :center 
          
      confirmed_date =  @delivery_order.confirmed_at.in_time_zone(LOCAL_TIME_ZONE)
      text "Date: #{confirmed_date.day}/#{confirmed_date.month}/#{confirmed_date.year}", 
          :size => 12, 
          :align => :center
    end 
  end
  
  def company_customer_details
    gap = 0 
    box_separator = 20 
    
    half_page = @page_width/2
    width = half_page - box_separator
    @company = Company.first 
    
    # @customer = @delivery_order.customer
    
    bounding_box( [0,cursor], :width => @page_width) do
      bounding_box([gap, bounds.top - gap], :width => width) do 
        text  "#{@company.name}"
        text  "#{@company.address}"
        text  "#{@company.phone}"
      end
      
      # if not @customer.nil?
      #   bounding_box([half_page + box_separator, bounds.top - gap], :width => width) do 
      #     text "#{@customer.name}"
      #     text "#{@delivery_order.delivery_address}"
      #   end 
      # end
    end
  end
    
   
   
  def document_details
    move_down 40
    total_delivery_entries = @delivery_order.delivery_entries.count 
    
    # table document_data , :position => :center , :width => @page_width -100 do
    table document_data , :position => :center  do
      row(0).font_style = :bold
      row( total_delivery_entries + 1).font_style = :bold 
      columns(1..3).align = :left
      self.header = true
      # self.column_widths = { 1 => 400 }
      self.column_widths = { 
          0 => 30 , #  entry number  
          1 => 250,  # the item description 
          2 => 50, # the quantity
          3 => 100, # the image 
          4 => 100,
          5 => 100
      }
      row(0).height = 40
    end
     
  end
   
  def document_data_header
    [["No", "Item", "Qty", "Qty Confirmed", "Qty Returned", "Qty Lost"]] 
  end
  
  def document_data_body
    count = 0
    (@delivery_order.delivery_entries).map do |delivery_entry|
      count = count + 1 
      item = delivery_entry.item 
      
      [ "#{count}", 
        "#{item.name} ", delivery_entry.quantity_sent,
        delivery_entry.quantity_confirmed,
        delivery_entry.quantity_returned, 
        delivery_entry.quantity_lost 
       ]
    end
  end
  
  def make_cell_image_placeholder
    make_cell("", {
      :height => 100
    })
  end
   
  def document_data 
    count = 0
    total_price_in_sales_order = BigDecimal("0")
    document_data_header + document_data_body  
  end
   
  def precision(num)
    @view.number_with_precision(num, :precision => 2)
  end
   
  def regards_message
    move_down 50
    # text "Thank You," ,:indent_paragraphs => 400
    move_down 6
    # text "XYZ",
    # :indent_paragraphs => 370, :size => 14, style:  :bold
  end
  
  def page_numbering
    string = "<page> / <total>" # Green page numbers 1 to 7
    options = {
      :at => [bounds.right - 150, bounds.top], 
      :width => 150, :align => :right, 
      :start_count_at => 1 
    } 
    number_pages string, options
  end
 
end