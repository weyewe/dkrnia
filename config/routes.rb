Dikarunia::Application.routes.draw do
  devise_for :users
  root :to => 'home#index'
  netzke
  
  devise_scope :user do
    get "sign_in", :to => "devise/sessions#new"
  end
  
  match 'report' => 'home#report', :as => :report 
  netzke
  
  match 'edit_main_company' => 'companies#edit_main_company', :as => :edit_main_company, :method => :post 
  match 'update_company/:id' => 'companies#update_company', :as => :update_company, :method => :post 
  
  resources :users
  resources :app_users
  resources :employees
  resources :vendors 
  resources :item_categories do 
    resources :items 
  end
  
  resources :items 
  resources :items do
    resources :stock_migrations 
  end
  
  resources :purchase_orders do
    resources :purchase_order_entries 
  end
  resources :purchase_order_entries
  
  resources :purchase_receivals do
    resources :purchase_receival_entries 
  end
  resources :purchase_receival_entries
  
  match 'search_item'  => 'items#search_item' , :as => :search_item
  match 'search_vendor'  => 'vendors#search_vendor' , :as => :search_vendor
  match 'search_purchase_order' => 'purchase_orders#search_purchase_order' , :as => :search_purchase_order
  match 'search_purchase_order_entry'  => 'purchase_order_entries#search_purchase_order_entry' , :as => :search_purchase_order_entry
  match 'search_employee' => "employees#search_employee" , :as => :search_employee
  
  resources :stock_migrations
  match 'generate_stock_migration'  => 'stock_migrations#generate_stock_migration' , :as => :generate_stock_migration, :method => :post 
  
  resources :stock_adjustments
  match 'generate_stock_adjustment'  => 'stock_adjustments#generate_stock_adjustment' , :as => :generate_stock_adjustment, :method => :post 
  
  
  resources :deliveries do
    resources :delivery_entries 
  end
  resources :delivery_entries 
  

=begin
  USER SETTING
=end
  match 'edit_credential' => "passwords#edit_credential" , :as => :edit_credential
  match 'update_password' => "passwords#update" , :as => :update_password, :method => :put
  
##################################################
##################################################
######### APP_USER 
##################################################
##################################################
  match 'update_app_user/:user_id' => 'app_users#update_app_user', :as => :update_app_user , :method => :post 
  match 'delete_app_user' => 'app_users#delete_app_user', :as => :delete_app_user , :method => :post



##################################################
##################################################
######### PURCHASE_ORDER 
##################################################
################################################## 
  match 'confirm_purchase_order/:purchase_order_id' => "purchase_orders#confirm_purchase_order", :as => :confirm_purchase_order, :method => :post
  
##################################################
##################################################
######### PURCHASE_RECEIVAL
##################################################
################################################## 
  match 'confirm_purchase_receival/:purchase_receival_id' => "purchase_receivals#confirm_purchase_receival", :as => :confirm_purchase_receival, :method => :post
  
##################################################
##################################################
######### DELIVERY
##################################################
##################################################  
  match 'confirm_delivery/:delivery_id' => "deliveries#confirm_delivery", :as => :confirm_delivery, :method => :post
  match 'finalize_delivery/:delivery_id' => "deliveries#finalize_delivery", :as => :finalize_delivery, :method => :post 
  match 'edit_post_delivery_delivery_entry/:delivery_entry_id'  => 'delivery_entries#edit_post_delivery_delivery_entry', :as => :edit_post_delivery_delivery_entry , :method => :get
  match 'update_post_delivery_delivery_entry/:delivery_entry_id'  => 'delivery_entries#update_post_delivery_delivery_entry', :as => :update_post_delivery_delivery_entry , :method => :post
  match 'print_delivery/:delivery_id' => 'deliveries#print_delivery' , :as => :print_delivery

##################################################
##################################################
######### REPORT
##################################################
##################################################
  match 'generate_purchase_order_details' => 'purchase_orders#generate_details' , :as => :generate_purchase_order_details
  match 'purchase_order_details' => 'purchase_orders#details' , :as => :purchase_order_details 
  match 'purchase_receival_details' => 'purchase_receivals#details' , :as => :purchase_receival_details 
  match 'delivery_details' => 'deliveries#details' , :as => :delivery_details 

  
end
