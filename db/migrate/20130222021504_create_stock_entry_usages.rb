class CreateStockEntryUsages < ActiveRecord::Migration
  def change
    create_table :stock_entry_usages do |t|
      t.integer :quantity 
      
      t.integer :source_document_entry_id 
      t.integer :source_document_id 
      
      t.string :source_document_entry 
      t.string :source_document
      
      
      t.integer :stock_entry_id 
      
      t.integer :case , :default => STOCK_ENTRY_USAGE[:delivery]
      
      t.timestamps
    end
  end
end
