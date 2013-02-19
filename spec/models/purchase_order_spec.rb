require 'spec_helper'

describe PurchaseOrder do
  before(:each) do
    role = {
      :system => {
        :@administrator => true
      }
    }

    Role.create!(
    :name        => ROLE_NAME[:admin],
    :title       => 'Administrator',
    :description => 'Role for @administrator',
    :the_role    => role.to_json
    )
    @admin_role = Role.find_by_name ROLE_NAME[:admin]
    first_role = Role.first



    @company = Company.create(:name => "Super metal", :address => "Tanggerang", :phone => "209834290840932")
    @admin = User.create_main_user(   :email => "admin@gmail.com" ,:password => "willy1234", :password_confirmation => "willy1234") 

    @admin.set_as_main_user

    # create vendor  => OK 
    @vendor = Vendor.create({
        :name =>"Monkey Crazy", 
        :contact_person =>"", 
        :phone =>"", 
        :mobile =>"", 
        :bbm_pin =>"", 
        :email =>"", 
        :address =>""})

    # create item category
    @base_item_category =  ItemCategory.create_base_object( @admin, :name => "Base Item" ) 

    # create item  


    @test_item  = Item.create_by_employee(  @admin,  {
      :name => "Test Item",
      :supplier_code => "BEL324234",
      :customer_code => 'CCCL222',
      :item_category_id => @base_item_category.id 
    })


    # create stock migration
    @migration_quantity = 200 
    @test_item_migration =  StockMigration.create_by_employee(@admin, {
      :item_id => @test_item.id,
      :quantity => @migration_quantity
    })  
 
    @test_item.reload 
  end
  
  it 'should create valid admin' do
    @admin.errors.messages.each do |msg|
      puts "ADMIN_ERRROR: #{msg}"
    end
    @admin.should be_valid 
  end
    
  it 'should create purchase order' do
    
    puts "The admin id; #{@admin.id}"
    @purchase_order = PurchaseOrder.create_by_employee( @admin, {
      :vendor_id => @vendor.id 
    } ) 
    
    @purchase_order.errors.messages.each do |msg|
      puts "THE MSG: #{msg}"
    end
    
    @purchase_order.should be_valid 
  end
  
  it 'should create purchase order entry ' do
    @purchase_order = PurchaseOrder.create_by_employee( @admin, {
      :vendor_id => @vendor.id 
    } )
    @purchase_order_entry = PurchaseOrderEntry.create_by_employee( @admin, @purchase_order, {
      :item_id => @test_item.id ,
      :quantity => 6 
    } ) 
    
    @purchase_order_entry.should be_valid
  end
end
