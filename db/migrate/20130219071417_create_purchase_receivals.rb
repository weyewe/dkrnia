class CreatePurchaseReceivals < ActiveRecord::Migration
  def change
    create_table :purchase_receivals do |t|
      t.integer :vendor_id
      
      t.date :receival_date 
      
      t.boolean :is_confirmed 

      t.timestamps
    end
  end
end
