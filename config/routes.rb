Dikarunia::Application.routes.draw do
  devise_for :users
  root :to => 'home#index'
  
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
  
  match 'search_item'  => 'items#search_item' , :as => :search_item
  match 'search_vendor'  => 'vendors#search_vendor' , :as => :search_vendor
  
  
  resources :stock_migrations
  match 'generate_stock_migration'  => 'stock_migrations#generate_stock_migration' , :as => :generate_stock_migration, :method => :post 
  
  resources :stock_adjustments
  match 'generate_stock_adjustment'  => 'stock_adjustments#generate_stock_adjustment' , :as => :generate_stock_adjustment, :method => :post 
  
  
  

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
end
