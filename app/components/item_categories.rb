class ItemCategories < Netzke::Basepack::Grid
  
  
  
  def configure(c)
    super
    c.model = "ItemCategory" 
    c.columns = [
      :name 
    ]
  end

  # include Netzke::Weyewe::Inspectable
  include PgGridTweaks # the mixin , defining sorter 
  include OnlyReadGrid
end
