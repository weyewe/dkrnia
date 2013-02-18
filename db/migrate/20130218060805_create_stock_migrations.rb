class CreateStockMigrations < ActiveRecord::Migration
  def change
    create_table :stock_migrations do |t|

      t.timestamps
    end
  end
end
