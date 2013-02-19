require 'spec_helper'

describe StockAdjustment do
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

    # create stock adjustment 
    # StockAdjustment.create_item_adjustment(@admin , @test_item , 150 ) 

    # create purchase  + purchase entry 

    # create purchase receive + purchase receive entry 
    # create delivery  + delivery entry 
      # delivery case: inspection or call. Nevertheless, put it in the note field 


    # that's it for prototype #1
    @test_item.reload 
  end
  
  it 'sanity check: have test_item, test_item_migration, valid quantity' do
    @test_item.should be_valid
    @test_item_migration.should be_valid 
    @test_item.ready.should == @migration_quantity    
  end
  
  it 'should be allowed to create stock_adjustment' do
    stock_adjustment = StockAdjustment.create_item_adjustment(@admin , @test_item , 150 ) 
    stock_adjustment.should be_valid 
  end
  
  context "creating stock adjustment: negative adjustment (physical quantity < data)"  do
    before(:each) do
      @ready_item = @test_item.ready
      @diff = 50 
      @physical_item = @ready_item - @diff
      @initial_ready = @test_item.ready 
      @stock_adjustment = StockAdjustment.create_item_adjustment(@admin , @test_item , @physical_item  )
    
      @test_item.reload  
    end
    
    it 'should create stock_adjustment' do
      @stock_adjustment.should be_valid 
    end
    
    it 'should have adjustment case as deduction' do
      @stock_adjustment.adjustment_case.should == STOCK_ADJUSTMENT_CASE[:deduction]
    end
    
    it 'should update the ready item to reflect adjustment' do
      @final_ready = @test_item.ready 
      diff = @initial_ready - @final_ready 
      diff.should == @diff 
    end
  end
  
  context "creating stock adjustment: positive adjustment (physical quantity > data)" 
end
