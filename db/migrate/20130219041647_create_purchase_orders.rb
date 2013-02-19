class CreatePurchaseOrders < ActiveRecord::Migration
  def change
    create_table :purchase_orders do |t|
      
      t.integer :creator_id 
      t.integer :vendor_id  
      
      t.string  :code  
      
      t.boolean :is_confirmed , :default => false  
      t.integer :confirmer_id 
      t.datetime :confirmed_at 
      
      t.boolean :is_deleted , :default => false

      t.timestamps
    end
  end
end
