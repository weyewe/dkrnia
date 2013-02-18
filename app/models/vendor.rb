class Vendor < ActiveRecord::Base
  attr_accessible :name, :contact_person, :phone, :mobile , :email, :bbm_pin, :address
  
  validates_presence_of :name 
  validates_uniqueness_of :name 
  
  validate :unique_non_deleted_name 
  
  def unique_non_deleted_name
    current_object = self
     
     # claim.status_changed?
    if not current_object.name.nil? 
      if not current_object.persisted? and current_object.has_duplicate_entry?  
        errors.add(:name , "Sudah ada vendor di masa lalu  dengan nama sejenis" )  
      elsif current_object.persisted? and 
            current_object.name_changed?  and
            current_object.has_duplicate_entry?   
            # if duplicate entry is itself.. no error
            # else.. some error
            
          if current_object.duplicate_entries.count ==1  and 
              current_object.duplicate_entries.first.id == current_object.id 
          else
            errors.add(:name , "Sudah ada vendor di masa lalu  dengan nama sejenis" )  
          end 
      end
    end
  end
  
  def has_duplicate_entry?
    current_object=  self  
    self.class.find(:all, :conditions => ['lower(name) = :name and is_deleted = :is_deleted  ', 
                {:name => current_object.name.downcase, :is_deleted => false }]).count != 0  
  end
  
  def duplicate_entries
    current_object=  self  
    return self.class.find(:all, :conditions => ['lower(name) = :name and is_deleted = :is_deleted  ', 
                {:name => current_object.name.downcase, :is_deleted => false  }]) 
  end
  
  
  
  
  def self.active_objects
    self.where(:is_deleted => false).order("created_at DESC")
  end
  
  def delete
    self.is_deleted = true
    self.save
  end
  
end
