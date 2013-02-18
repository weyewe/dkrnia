class CreateStockMigrations < ActiveRecord::Migration
  def change
    create_table :stock_migrations do |t|
      t.integer :item_id 
      t.string :code 
      t.integer :creator_id 
      
      t.integer :quantity 
      t.decimal :average_cost ,  :precision => 11, :scale => 2, :default => 0.0
      
      t.boolean :is_confirmed, :default => false 
      t.integer :confirmer_id 
      t.datetime :confirmed_at 

      t.timestamps
    end
  end
end
