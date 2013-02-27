class PurchaseOrders < Netzke::Basepack::Grid
  
  
  
  def configure(c)
    super
    c.model = "PurchaseOrder"
    c.inspect_url =   '/purchase_order_details'
    c.columns = [
      :code,
      :vendor__name,
      :confirmed_at # ,
      #       {
      #         name: :inspect, 
      #         width: 20 
      #       }
    ]
  end

  # include Netzke::Weyewe::Inspectable
  include PgGridTweaks # the mixin , defining sorter 
  include OnlyReadGrid
end
