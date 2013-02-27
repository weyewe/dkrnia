class DeliveryEntries < Netzke::Basepack::Grid
  
  # how can we not show the add, delete?
  # read only ? in the Netzke::Basepack::Grid
  # only allow add in form? How?
  
  def configure(c)
    super
    c.model = "DeliveryEntry"
    c.columns = [
      :delivery__code,
      :item__name,
      :quantity_sent,
      :quantity_confirmed, 
      :quantity_returned, 
      :quantity_lost 
    ]
  end
   
  # The inspect action (and column)

  include PgGridTweaks # the mixin , defining sorter 
  include OnlyReadGrid
end
