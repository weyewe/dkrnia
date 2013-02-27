class HomeController < ApplicationController
  skip_before_filter :role_required,  :only => [  
                                                :index 
                                                ]
  
  def index
  
  end
   
   
  def report
    render(:layout => "layouts/report")
  end
end
