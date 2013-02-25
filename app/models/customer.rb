class Customer < ActiveRecord::Base
  include UniqueNonDeleted
  attr_accessible :name, :contact_person, :phone, :mobile , :email, :bbm_pin, :address
  
  validates_presence_of :name 
  
  validate :unique_non_deleted_name 
  
  def unique_object
    "customer"
  end
  
  def self.active_objects
    self.where(:is_deleted => false).order("created_at DESC")
  end
  
  def delete( employee )
    self.is_deleted = true
    self.save
  end
  
end
