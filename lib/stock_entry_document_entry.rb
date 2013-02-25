module StockEntryDocumentEntry
  
  
  def stock_entry
    StockEntry.where(
      :source_document_entry_id => self.id,
      :source_document_entry => self.class.to_s
    ).first 
  end
  
  def stock_entries
    StockEntry.where(
      :source_document_entry_id => self.id,
      :source_document_entry => self.class.to_s
    )
  end
end