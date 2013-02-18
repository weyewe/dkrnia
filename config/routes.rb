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


  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
