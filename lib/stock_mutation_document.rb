module StockMutationDocument
  
  
  def stock_mutations
    StockMutation.where(
      :source_document_id => self.id,
      :source_document => self.class.to_s
    )
  end
end