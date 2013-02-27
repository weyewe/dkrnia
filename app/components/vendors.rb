class Vendors < Netzke::Basepack::Grid #Netzke::Communitypack::LiveSearchGrid # 
  
   # Netzke::Communitypack::LiveSearchGrid
  
  
  # how can we not show the add, delete?
  # read only ? in the Netzke::Basepack::Grid
  # only allow add in form? How?
  
  def configure(c)
    super
    c.model = "Vendor"
    c.columns = [
      :name,
      :contact_person,
      :phone,
      :mobile, 
      :email,
      :bbm_pin,
      :address 
    ]
  end

  include PgGridTweaks # the mixin , defining sorter 
  include OnlyReadGrid
end
