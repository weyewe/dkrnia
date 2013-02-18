role = {
  :system => {
    :administrator => true
  }
}

Role.create!(
:name        => ROLE_NAME[:admin],
:title       => 'Administrator',
:description => 'Role for administrator',
:the_role    => role.to_json
)
admin_role = Role.find_by_name ROLE_NAME[:admin]
first_role = Role.first
 


company = Company.create(:name => "Super metal", :address => "Tanggerang", :phone => "209834290840932")
admin = User.create_main_user(   :email => "admin@gmail.com" ,:password => "willy1234", :password_confirmation => "willy1234") 

admin.set_as_main_user

# create vendor  => OK 
Vendor.create({
    :name =>"Monkey Crazy", 
    :contact_person =>"", 
    :phone =>"", 
    :mobile =>"", 
    :bbm_pin =>"", 
    :email =>"", 
    :address =>""})

# create item category
# create item  + item category 
 
# create stock migration 
# create purchase  + purchase entry 
# create purchase receive + purchase receive entry 
# create delivery  + delivery entry 
  # delivery case: inspection or call. Nevertheless, put it in the note field 


# that's it for prototype #1 