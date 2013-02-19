class CreatePurchaseOrderEntries < ActiveRecord::Migration
  def change
    create_table :purchase_order_entries do |t|

      t.integer :creator_id
      t.integer :purchase_order_id  

      t.string  :code
      t.integer :item_id 

      t.integer :quantity 

      t.boolean :is_confirmed, :default => false  

      t.boolean :is_deleted, :default => false
      t.timestamps
    end
  end
end
