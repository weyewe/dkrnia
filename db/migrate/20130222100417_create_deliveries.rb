class CreateDeliveries < ActiveRecord::Migration
  def change
    create_table :deliveries do |t|
      t.integer :employee_id 
      t.integer :creator_id
      
      t.date :delivery_date  
      
      t.string  :code  
      
      t.boolean :is_confirmed , :default => false  
      t.integer :confirmer_id 
      t.datetime :confirmed_at
      
      t.boolean :is_finalized, :default => false 
      t.integer :finalizer_id 
      t.datetime :finalized_at 
      
      t.boolean :is_deleted, :default => false
      
      t.timestamps
    end
  end
end
