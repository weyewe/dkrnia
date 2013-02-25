class CreateDeliveryEntries < ActiveRecord::Migration
  def change
    create_table :delivery_entries do |t|
      t.integer :creator_id 
      t.string :code 
      
      t.integer :item_id 
      t.integer :delivery_id 
      t.integer :quantity_sent       , :default => 0 
      t.integer :quantity_confirmed  , :default => 0 
      t.integer :quantity_returned   , :default => 0     # not a sales return.. just simply put it back to the repo 
      t.integer :quantity_lost       , :default => 0 
      
      t.text :note 

      t.boolean :is_confirmed, :default => false 
      t.boolean :is_deleted, :default => false
      
      t.boolean :is_finalized , :default => false 
      
      t.timestamps
    end
  end
end
