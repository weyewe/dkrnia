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
    
    @second_test_item_migration  = StockMigration.create_by_employee(@admin, {
      :item_id => @second_test_item.id,
      :quantity => 10
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
     
     @second_quantity_purchased  =  3
     @second_purchase_order_entry = PurchaseOrderEntry.create_by_employee( @admin, @purchase_order, {
        :item_id => @second_test_item.id ,
        :quantity => @second_quantity_purchased
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
    @first_purchase_order_entry_quantity = @update_quantity
    @test_item.reload 
  end
  
  it 'should have the pending receival' do
    @test_item.pending_receival.should == @update_quantity
  end
  
  it 'should create the purchase order + confirm it ' do
    @purchase_order.should be_valid 
    @purchase_order.is_confirmed.should be_true 
  end
  
  it 'should create purchase receival' do
    @purchase_receival = PurchaseReceival.create_by_employee( @admin, {
      :vendor_id => @vendor.id
    } )
    @purchase_receival.should be_valid 
  end
  
  it 'should not create purchase receival if no vendor' do
    @purchase_receival = PurchaseReceival.create_by_employee( @admin, {
      :vendor_id =>  nil 
    } )
    @purchase_receival.should_not be_valid 
  end
   
  context "creating purchase receival => update the shite" do
    before(:each) do
      @purchase_receival = PurchaseReceival.create_by_employee( @admin, {
        :vendor_id => @vendor.id
      } ) 
      @purchase_order_entry.reload 
    end
    
    it 'should have purchase_order_entry' do
      @purchase_order_entry.should be_valid 
    end
    
    it 'should create the purchase receival entry if the quantity is between 0 < x < ordered ' do
      received_quantity = @purchase_order_entry.quantity - 2 
      @purchase_receival_entry = PurchaseReceivalEntry.create_by_employee( @admin, 
                @purchase_receival, 
                {
                  :purchase_order_entry_id => @purchase_order_entry.id ,
                  :quantity => received_quantity
                }) 
                
      @purchase_receival_entry.should be_valid 
    end
    
    it 'should not create purchase receival entry if the quantity is <= 0 ' do
      @purchase_receival_entry = PurchaseReceivalEntry.create_by_employee( @admin, 
                @purchase_receival, 
                {
                  :purchase_order_entry_id => @purchase_order_entry.id ,
                  :quantity => 0 
                }) 
      @purchase_receival_entry.should_not be_valid
    end
    
    it 'should not create purchase receival entry if the quantity is >= ordered quantity in that purchase order entry ' do
      @purchase_receival_entry = PurchaseReceivalEntry.create_by_employee( @admin, 
                @purchase_receival, 
                {
                  :purchase_order_entry_id => @purchase_order_entry.id ,
                  :quantity => @purchase_order_entry.quantity + 1  
                }) 
                
      @purchase_receival_entry.should_not be_valid
    end
    
    context "creating purchase receival entry" do
      before(:each) do
        @diff = 2
        @received_quantity = @purchase_order_entry.quantity - @diff  
        @purchase_receival_entry = PurchaseReceivalEntry.create_by_employee( @admin, 
                  @purchase_receival, 
                  {
                    :purchase_order_entry_id => @purchase_order_entry.id ,
                    :quantity => @received_quantity
                  })
      end
      
      it 'should create purchase receival entry' do
        @purchase_receival_entry.should be_valid 
      end
      
      it 'should preserve uniqueness: 1 purchase order entry in 1 receival' do
        @diff = 2
        @purchase_receival_entry = PurchaseReceivalEntry.create_by_employee( @admin, 
                  @purchase_receival, 
                  {
                    :purchase_order_entry_id => @purchase_order_entry.id ,
                    :quantity => @diff
                  })
        @purchase_receival_entry.should_not be_valid 
      end
      
      context "confirm the purchase receival" do
        before(:each) do
          @test_item.reload 
          @initial_ready_quantity = @test_item.ready
          @initial_pending_receival_quantity =  @test_item.pending_receival
          @purchase_receival.confirm(@admin) 
          @purchase_receival_entry.reload 
          @test_item.reload
        end
        
        it 'should confirm the purchase receival' do
           @purchase_receival.is_confirmed.should be_true 
         end
         
         it 'should confirm the purchase receival entry' do
           @purchase_receival_entry.is_confirmed.should be_true 
         end
         
         it 'should reduce the pending receival quantity' do
           @final_pending_receival_quantity = @test_item.pending_receival
           diff = @initial_pending_receival_quantity   - @final_pending_receival_quantity
           diff.should == @received_quantity
         end

        it 'should increase the ready item' do
          @final_ready_quantity = @test_item.ready
          diff = @final_ready_quantity - @initial_ready_quantity
          diff.should == @received_quantity
        end
        
        it 'should have pending receival for the second item' do
          @second_test_item.reload
          @second_test_item.pending_receival.should == @second_quantity_purchased
        end
        
        
        context "[post confirm purchase receive] change the purchase_order_entry" do
          before(:each) do
            @second_diff = 1
            @new_quantity = @second_quantity_purchased - @second_diff 
            @purchase_receival_entry.reload
            @test_item.reload
            @second_test_item.reload
            @first_item_initial_pending_receival = @test_item.pending_receival 
            @initial_second_pending_receival = @second_test_item.pending_receival
            @purchase_receival_entry.update_by_employee( @admin, {
              :purchase_order_entry_id => @second_purchase_order_entry.id ,
              :quantity => @new_quantity
            } ) 
            @test_item.reload
            @second_test_item.reload
          end
          
          # it 'should point to the new purchase order entry' do
          #   @purchase_receival_entry.purchase_order_entry_id.should == @second_purchase_order_entry.id
          #   @purchase_receival_entry.quantity.should ==  @new_quantity
          # end
          # 
          # it 'should allow change of purchase order entry' do
          #   @purchase_receival_entry.errors.size.should_not == 0 
          # end
          
          it 'should consume the new purchase order entry' do
            puts "initial second pending receival; #{@initial_second_pending_receival}"
            
            @final_second_pending_receival = @second_test_item.pending_receival
            puts "final second pending receival: #{@final_second_pending_receival}"
            puts "quantity assigned: #{@new_quantity}"
            diff = @initial_second_pending_receival - @final_second_pending_receival
            diff.should == @new_quantity 
          end
          
          it 'should update the old item pending receival' do
            @first_item_initial_pending_receival = @test_item.pending_receival 
            @first_item_initial_pending_receival.should == @first_purchase_order_entry_quantity
          end
        end
        
        context "[post confirm purchase receive] change the purchase_order_entry and quantity" do
        end
        
        context "[post confirm purchase receive] delete" do
        end
        
      end 
    end
  end
 

end
