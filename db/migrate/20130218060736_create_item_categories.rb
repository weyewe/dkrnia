class CreateItemCategories < ActiveRecord::Migration
  def change
    create_table :item_categories do |t|
      t.string :name
      t.integer :parent_id
      t.integer :creator_id 
      t.boolean :is_base_category, :default => false 
      
      t.integer :lft
      t.integer :rgt
      t.integer :depth # this is optional.

      t.boolean :is_deleted, :default => false

      t.timestamps
    end
  end
end
