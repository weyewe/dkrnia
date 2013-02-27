class Items < Netzke::Communitypack::LiveSearchGrid
  
  
  
  def configure(c)
    super
    c.model = "StockMutation" 
    c.columns = [
      :quantity,
      { :name => :mutation_status,
        :width => 30,
        :header => "",
        :tooltip => "Status mutasi",
        :getter => lambda { |r|
          bulb = r.updated ? "on" : "off"
          if r.mutation_status == MUTATION_STATUS[:deduction] 
            return "-"
          elsif r.mutation_status == MUTATION_STATUS[:addition] 
            return "+"
          end
        }
      },
      { :name => :mutation_case,
        :width => 30,
        :header => "",
        :tooltip => "Kasus",
        :getter => lambda { |r|
          bulb = r.updated ? "on" : "off"
          if r.mutation_case == MUTATION_CASE[:stock_migration] 
            return "Migrasi"
          elsif r.mutation_case == MUTATION_STATUS[:purchase_receival] 
            return "Penerimaan"
          elsif r.mutation_case == MUTATION_STATUS[:stock_adjustment]
            return "Penyesuaian"
          elsif r.mutation_case == MUTATION_STATUS[:delivery] 
            return "Pengiriman"
          elsif r.mutation_case == MUTATION_STATUS[:delivery_lost] 
            return "Hilang Pengiriman" 
          elsif r.mutation_case == MUTATION_STATUS[:delivery_returned]   
            return "Retur Pengiriman"
          else 
            return ""
          end
        }
      }
    ]
  end

  # include Netzke::Weyewe::Inspectable
  include PgGridTweaks # the mixin , defining sorter 
  include OnlyReadGrid
end
