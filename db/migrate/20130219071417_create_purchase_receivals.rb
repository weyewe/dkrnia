class CreatePurchaseReceivals < ActiveRecord::Migration
  def change
    create_table :purchase_receivals do |t|
      t.integer :vendor_id
      t.integer :creator_id
      
      t.date :receival_date 
      
      t.string  :code  
      
      t.boolean :is_confirmed , :default => false  
      t.integer :confirmer_id 
      t.datetime :confirmed_at
      
      t.boolean :is_deleted, :default => false 
      

      t.timestamps
    end
  end
end
