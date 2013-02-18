class CreateStockEntries < ActiveRecord::Migration
  def change
    create_table :stock_entries do |t|

      t.timestamps
    end
  end
end
