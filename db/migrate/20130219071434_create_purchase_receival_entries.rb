class CreatePurchaseReceivalEntries < ActiveRecord::Migration
  def change
    create_table :purchase_receival_entries do |t|
      t.integer :creator_id 
      t.string :code 
      
      t.integer :item_id 
      t.integer :purchase_receival_id 
      t.integer :purchase_order_entry_id
      t.integer :vendor_id 
      t.integer :quantity 

      t.boolean :is_confirmed, :default => false 
      t.boolean :is_deleted, :default => false
      t.timestamps
    end
  end
end
