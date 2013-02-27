class Items < Netzke::Communitypack::LiveSearchGrid
  
  
  
  def configure(c)
    super
    c.model = "Item" 
    c.columns = [
      :supplier_code,
      :customer_code,
      :name ,
      :ready,
      :pending_receival 
    ]
  end

  # include Netzke::Weyewe::Inspectable
  include PgGridTweaks # the mixin , defining sorter 
  include OnlyReadGrid
end
