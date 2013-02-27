class Deliveries < Netzke::Basepack::Grid
  
  
  
  def configure(c)
    super
    c.model = "Delivery"
    c.inspect_url =   '/delivery_details'
    c.columns = [
      :code,
      :employee__name,
      :confirmed_at # ,
       #      {
       #        name: :inspect, 
       #        width: 20 
       #      }
    ]
  end

  # include Netzke::Weyewe::Inspectable
  include PgGridTweaks # the mixin , defining sorter 
  include OnlyReadGrid
end
