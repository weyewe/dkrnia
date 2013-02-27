class StockMutations < Netzke::Basepack::Grid
  
  
  
  def configure(c)
    super
    c.model = "StockMutation" 
    c.columns = [
      :quantity,
      { :name => :render_mutation_case,
        :header => "Kasus"
      },
      { :name => :render_mutation_status,
        :header => "Status"
      },
      {
        :name => :document_code,
        :header => "Document"
      }
    ]
  end

  # include Netzke::Weyewe::Inspectable
  include PgGridTweaks # the mixin , defining sorter 
  include OnlyReadGrid
end
