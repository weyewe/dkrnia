# As Heroku uses PG, which does not sort records by ids, we need to do it in our grids, so the user experience with inline editing of data is less confusing
module OnlyReadGrid
  def configure(c)
    c.bbar = [:search]
    c.read_only = true
    super
  end
end
