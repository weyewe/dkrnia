class Application < Netzke::Basepack::Viewport

  # A simple mockup of the User model
  class User < Struct.new(:email, :password)
    def initialize
      self.email = "demo@netzke.org"
      self.password = "netzke"
    end
    def self.authenticate_with?(email, password)
      instance = self.new
      [email, password] == [instance.email, instance.password]
    end
  end

  action :data_entry do |c|
    c.icon = :information
  end

  action :sign_in do |c|
    c.icon = :door_in
  end

  action :sign_out do |c|
    c.icon = :door_out
    c.text = "Sign out #{current_user.email}" if current_user
  end

  js_configure do |c|
    c.layout = :fit
    c.mixin # will add the extra js code from components/application/javascripts/application.js << filename.js
  end

  def configure(c)
    super
    c.intro_html = "Laporan keluar masuk barang Dikarunia"
    c.items = [
      { layout: :border,
        tbar: [header_html, '->', :data_entry ],
        items: [
          { region: :west, item_id: :navigation, width: 300, split: true, xtype: :treepanel, root: menu, root_visible: false, title: "Navigation" },
          { region: :center, layout: :border, border: false, items: [
            { item_id: :info_panel, region: :north, height: 35, body_padding: 5, split: true, html: initial_html },
            { item_id: :main_panel, region: :center, layout: :fit, border: false, items: [{body_padding: 5, html: "Pilih laporan di sisi kiri. Hasil akan ditampilkan disini."}] } # items is only needed here for cosmetic reasons (initial border)
          ]}
        ]
      }
    ]
  end

  #
  # Components, specific for supermetal 
  #

# Company 
 
  component :employees do |c| 
    c.desc = "Daftar karyawan aktif"
  end
  
  component :vendors do |c| 
    c.desc = "Daftar Vendor aktif"
  end
 
 
 
# Item FLOW
  component  :purchase_orders_and_purchase_order_entries do |c|
    c.desc = "Daftar pembelian barang dan sejarah penerimaan"
  end
  
  component :purchase_receivals_and_purchase_receival_entries do |c|
    c.desc = "Daftar Penerimaan Barang Barang"
  end 
  
  component :deliveries_and_delivery_entries do |c|
    c.desc = "Daftar Keluar barang"
  end
  
  # Item History 
  
  component :item_categories_and_items do |c|
    c.desc = "Daftar Barang dan Kategori Barang"
  end
    
  component :items_and_stock_mutations do |c|
    c.desc = "Mutasi Barang"
  end
   

  # Endpoints
  #
  #
  endpoint :sign_in do |params,this|
    user = User.new
    if User.authenticate_with?(params[:email], params[:password])
      session[:user_id] = 1 # anything; this is what you'd normally do in a real-life case
      this.netzke_set_result(true)
    else
      this.netzke_set_result(false)
      this.netzke_feedback("Wrong credentials")
    end
  end

  endpoint :sign_out do |params,this|
    session[:user_id] = nil
    this.netzke_set_result(true)
  end

protected

  def current_user
    @current_user ||= session[:user_id] && User.new
  end

  def link(text, uri)
    "<a href='#{uri}'>#{text}</a>"
  end

  def source_code_link(c)
    comp_file_name = c.klass.nil? ? c.name.underscore : c.klass.name.underscore
    uri = [NetzkeDemo::Application.config.repo_root, "app/components", comp_file_name + '.rb'].join('/')
    "<a href='#{uri}' target='_blank'>Source code</a>"
  end

  def header_html
    %Q{
      <div style="color:#333; font-family: Helvetica; font-size: 150%;">
        <a style="color:#B32D15;" href="http://sumet.herokuapp.com">SuperMetal</a>
      </div>
    }
  end

  def initial_html
    %Q{
      <div style="color:#333; font-family: Helvetica;">
        <img src='#{uri_to_icon(:information)}'/> 
      </div>
    }
  end

  def leaf(text, component, icon = nil)
    { text: text,
      icon: icon && uri_to_icon(icon),
      cmp: component,
      leaf: true
    }
  end

  def menu
    out = { :text => "Reports",
      :expanded => true,
      :children => [
        
        { :text => "Perusahaan",
          :expanded => true,
          :children => [
 
            leaf("Karyawan", :employees, :user_suit),
            leaf("Vendor", :vendors, :user_suit),
            leaf("Pembelian Barang", :purchase_orders_and_purchase_order_entries, :user_suit)
          ]
        },# ,
        #         
        { :text => "Keluar Masuk Barang",
           :expanded => true,
           :children => [
             leaf("Penerimaan Barang", :purchase_receivals_and_purchase_receival_entries, :user),
             leaf("Delivery", :deliveries_and_delivery_entries, :user)
             
           ]
        },
        { :text => "Inventory",
          :expanded => true,
          :children => [
            leaf("Kategori Barang", :item_categories_and_items, :user_suit), 
            leaf("Mutasi Stock", :items_and_stock_mutations, :user_suit) 
          ]
        }
      ]
    }
 
    out
  end
end
