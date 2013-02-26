class StockAdjustment < ActiveRecord::Base
  include StockMutationDocument
  include StockMutationDocumentEntry
  # attr_accessible :title, :body
  validates_presence_of :adjustment_case, 
                        :physical_quantity , :ready_quantity, :adjustment_quantity
  belongs_to :item
                        
  validate :diff_between_quantity_is_non_zero, 
          :physical_quantity_not_less_than_zero
  
  def diff_between_quantity_is_non_zero
    if self.ready_quantity == self.physical_quantity
      errors.add(:physical_quantity , "Perbedaan antara jumlah terdata dan jumlah aktual tidak boleh 0 " )  
    end
  end
  
  def physical_quantity_not_less_than_zero
    if   self.physical_quantity < 0 
      errors.add(:physical_quantity , "Kuantitas fisik tidak boleh < 0 " )  
    end
  end
   
  
  
  def StockAdjustment.generate_adjustment_code( item)
    datetime  =  DateTime.now
    year = datetime.year 
    month = datetime.month   
    total_stock_adjustment_created_this_month = StockAdjustment.where(:created_at => datetime.beginning_of_month..datetime.end_of_month   ).count  
    
    code =  'SADJ/' + year.to_s + '/' + 
                        month.to_s + '/' + 
                        (total_stock_adjustment_created_this_month + 1 ).to_s 
    
    
    return code
  end
  
  
  
  def self.create_item_adjustment(employee, item , physical_quantity ) 
    
    ActiveRecord::Base.transaction do
      ready_quantity = item.ready 
      new_object = StockAdjustment.new 
    
      adjustment_quantity =  physical_quantity  - ready_quantity 
      new_object.physical_quantity = physical_quantity
      new_object.ready_quantity = ready_quantity
      
      new_object.creator_id = employee.id 
      new_object.item_id = item.id 
      new_object.code=  StockAdjustment.generate_adjustment_code( item)
      
      physical_to_ready_diff  = physical_quantity  - ready_quantity 
    
      # puts "physical_to_ready_diff : #{physical_to_ready_diff}"
      if physical_to_ready_diff > 0 
        new_object.adjustment_quantity = physical_to_ready_diff
        new_object.adjustment_case = STOCK_ADJUSTMENT_CASE[:addition]
        
      elsif physical_to_ready_diff < 0  
        new_object.adjustment_quantity = physical_to_ready_diff * -1 
        new_object.adjustment_case = STOCK_ADJUSTMENT_CASE[:deduction] 
      elsif adjustment_quantity == 0  
      end
    
         
      if new_object.save
        StockMutation.create_stock_adjustment(employee,  new_object )
        
        # if new_object.adjustment_case == STOCK_ADJUSTMENT_CASE[:addition]
        #   StockEntry.generate_stock_adjustment_stock_entry( new_object )
        # elsif new_object.adjustment_case == STOCK_ADJUSTMENT_CASE[:deduction]
        #   StockEntryUsage.generate_stock_adjustment_stock_entry_usage( new_object ) 
        # end
        
      end
        
      
      return new_object
    end
     
  end
  
  
  def stock_entry
    return nil if self.adjustment_case == STOCK_ADJUSTMENT_CASE[:deduction] 
    
    StockEntry.find(:first, :conditions => {
      :entry_case => STOCK_ENTRY_CASE[:stock_adjustment], 
      :source_document => self.class.to_s, 
      :source_document_id => self.id 
    })
  end
  
  def is_addition?
     self.adjustment_case == STOCK_ADJUSTMENT_CASE[:addition]
  end
  
  def is_deduction?
     self.adjustment_case == STOCK_ADJUSTMENT_CASE[:deduction]
  end
  
end
