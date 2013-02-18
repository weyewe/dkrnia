class HomeController < ApplicationController
  skip_before_filter :role_required,  :only => [  
                                                :index 
                                                ]
  
  def index
  
  end
   
end
