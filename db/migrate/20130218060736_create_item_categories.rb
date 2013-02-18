class CreateItemCategories < ActiveRecord::Migration
  def change
    create_table :item_categories do |t|

      t.timestamps
    end
  end
end
