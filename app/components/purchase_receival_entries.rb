class PurchaseReceivalEntries < Netzke::Basepack::Grid
  
  # how can we not show the add, delete?
  # read only ? in the Netzke::Basepack::Grid
  # only allow add in form? How?
  
  def configure(c)
    super
    c.model = "PurchaseReceivalEntry"
    c.columns = [
      :purchase_receival__code,
      :item__name,
      :quantity 
    ]
  end
   
  # The inspect action (and column)

  include PgGridTweaks # the mixin , defining sorter 
  include OnlyReadGrid
end
