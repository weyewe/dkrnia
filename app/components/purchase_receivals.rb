class PurchaseReceivals < Netzke::Communitypack::LiveSearchGrid
  
  
  
  def configure(c)
    super
    c.model = "PurchaseReceival"
    c.inspect_url =   '/purchase_receival_details'
    c.columns = [
      :code,
      :vendor__name,
      :confirmed_at ,
      {
        name: :inspect, 
        width: 20 
      }
    ]
  end

  include Netzke::Weyewe::Inspectable
  include PgGridTweaks # the mixin , defining sorter 
  include OnlyReadGrid
end
