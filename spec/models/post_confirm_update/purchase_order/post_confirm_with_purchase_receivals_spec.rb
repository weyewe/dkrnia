require 'spec_helper'

describe PurchaseReceival do
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
    
    @second_test_item  = Item.create_by_employee(  @admin,  {
      :name => "Second Test Item",
      :supplier_code => "BEL3224234423224324",
      :customer_code => 'CCCL22343222',
      :item_category_id => @base_item_category.id 
    })


    # create stock migration
    @migration_quantity = 200 
    @test_item_migration =  StockMigration.create_by_employee(@admin, {
      :item_id => @test_item.id,
      :quantity => @migration_quantity
    })  
 
    @test_item.reload 
    
    
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
    @pre_confirm_pending_receival = @test_item.pending_receival
    @purchase_order.confirm(@admin)
    @test_item.reload
    @post_confirm_pending_receival = @test_item.pending_receival
    @update_quantity = 9
    @test_item.reload 
    @pre_update_pending_receival = @test_item.pending_receival
    @purchase_order_entry.update_by_employee(@admin, {
      :quantity => @update_quantity,
      :item_id => @test_item.id 
      })    
    @test_item.reload
    
    @purchase_receival = PurchaseReceival.create_by_employee( @admin, {
      :vendor_id => @vendor.id
    } ) 
    @purchase_order_entry.reload 
    
    @diff = 2
    @received_quantity = @purchase_order_entry.quantity - @diff  
    @purchase_receival_entry = PurchaseReceivalEntry.create_by_employee( @admin, 
        @purchase_receival, 
        {
          :purchase_order_entry_id => @purchase_order_entry.id ,
          :quantity => @received_quantity
        })
    @test_item.reload 
    @initial_ready_quantity = @test_item.ready
    @initial_pending_receival_quantity =  @test_item.pending_receival
    @purchase_receival.confirm(@admin) 
    @test_item.reload
    @purchase_receival_entry.reload 
  end
  
  it 'should have purchase receival and confirmed' do
    @purchase_receival.is_confirmed.should be_true 
    @purchase_receival_entry.is_confirmed.should be_true 
  end
   
  context "[purchase_receival present] updating purchase order entry: only quantity" do
    before(:each) do
      @test_item.reload
      @initial_pending_receival=  @test_item.pending_receival
      @purchase_order_entry.update_by_employee(@admin, {
         :quantity => @received_quantity ,
         :item_id => @test_item.id 
       })
      @purchase_order_entry.reload
      @test_item.reload
    end
    
    it 'should be updated' do
      @purchase_order_entry.should be_valid 
    end
    
    it 'should make the fulfilment to be true' do
      # take note: we are updating the ordered quantity to be received quantity.
      # hence, some calculation inside the update will take place and update the fufilled status
      @purchase_order_entry.is_fulfilled.should be_true 
    end
    
    it 'should deduct the item pending receival' do
      @final_pending_receival = @test_item.pending_receival
      diff = @initial_pending_receival - @final_pending_receival 
      diff.should == @diff 
    end
  end
  
  context "[purchase_receival present] updating purchase order entry:  quantity + item" do
    before(:each) do
      @test_item.reload
      @initial_pending_receival=  @test_item.pending_receival
      @purchase_order_entry.update_by_employee(@admin, {
         :quantity => @received_quantity ,
         :item_id => @second_test_item.id 
       })
      @purchase_order_entry.reload
      @test_item.reload
    end
    
    it 'should be updated' do
      @purchase_order_entry.errors.size.should_not == 0 
    end 
  end
  
  context "[purchase_receival present] delete the purchase order entry" do
    before(:each) do
      @purchase_order_entry.delete(@admin)
    end
    
    it 'should be invalid' do
      @purchase_order_entry.errors.size.should_not == 0 
    end
  end
end
