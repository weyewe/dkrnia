class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.integer :creator_id  
      
      t.string :name  
      t.string :supplier_code
      t.string :customer_code 
      t.integer :item_category_id 
      
      # it is updated whenever a stock is inputted to the system
      t.decimal :average_cost , :precision => 11, :scale => 2 , :default => 0  # 10^9 << max value 
      t.decimal :recommended_selling_price , :precision => 11, :scale => 2 , :default => 0  # 10^9 << max value
      
      
      # Stock Mutation.
      t.integer :ready , :default           => 0 
      t.integer :scrap , :default           => 0 
      t.integer :pending_delivery, :default => 0   # sum of all ordered, not delivered 
      t.integer :on_delivery, :default      => 0  # on the way to customer 
      
      t.integer :pending_receival 
      
      t.boolean :is_deleted , :default => false

      t.timestamps
    end
  end
end
