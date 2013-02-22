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
    
    @purchase_order_entry.errors.messages.each do |msg|
      puts "Error msg: #{msg}"
    end
    @purchase_order_entry.should be_valid
  end
    
   context "creating purchase order entry, not confirming" do
     before(:each) do
       @initial_pending_receival = @test_item.pending_receival
       @purchase_order = PurchaseOrder.create_by_employee( @admin, {
         :vendor_id => @vendor.id 
       } )
       
       @quantity_purchased  =  6
       @purchase_order_entry = PurchaseOrderEntry.create_by_employee( @admin, @purchase_order, {
         :item_id => @test_item.id ,
         :quantity => @quantity_purchased
       } ) 
   
       @test_item.reload 
       @final_pending_receival = @test_item.pending_receival
     end
     
     it 'should produce no  diff in pending_receival' do
       diff = @final_pending_receival - @initial_pending_receival 
       diff.should == 0 
     end
     
     context "confirming purchase order" do
       before(:each) do
         @pre_confirm_pending_receival = @test_item.pending_receival
         @purchase_order.confirm(@admin)
         @test_item.reload
         @post_confirm_pending_receival = @test_item.pending_receival
       end
       
       it 'should confirm purchase order' do
         @purchase_order.is_confirmed.should be_true 
       end
       
       it 'should change the number of pending_receival' do
         diff = @post_confirm_pending_receival - @pre_confirm_pending_receival
         diff.should == @quantity_purchased
       end
       
       context "post confirm update" do
         before(:each) do
           @update_quantity = 9
           @test_item.reload 
           @pre_update_pending_receival = @test_item.pending_receival
           @purchase_order_entry.update_by_employee(@admin, {
             :quantity => @update_quantity,
             :item_id => @test_item.id 
           })
           @test_item.reload 
         end
         
         it 'should alter the item#pending_receival' do
           @test_item.pending_receival.should == @update_quantity
         end
         
       end
       
       context "post confirm delete " do 
         before(:each) do
           @update_quantity = 9
           @test_item.reload 
           @pre_update_pending_receival = @test_item.pending_receival
           @purchase_order_entry.delete(@admin )
           @test_item.reload 
         end
         
         it 'should alter the item#pending_receival' do
           @test_item.pending_receival.should == 0 
         end
       end
     end
   end
 

end
