module StockEntryDocument
  
  
  def stock_entries
    StockEntry.where(
      :source_document_id => self.id,
      :source_document => self.class.to_s
    )
  end
end