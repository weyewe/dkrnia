class EmployeesController < ApplicationController
  before_filter :role_required, :except => [:search_employee]
  def new
    @objects = Employee.active_objects
    @new_object = Employee.new 
  end
  
  def create
    # HARD CODE.. just for testing purposes 
    # params[:employee][:town_id] = Town.first.id 
    @object = Employee.create( params[:employee] ) 
    if @object.valid?
      @new_object=  Employee.new
    else
      @new_object= @object
    end
    
  end
  
  def search_employee
    search_params = params[:q]
    
    @objects = [] 
    query = '%' + search_params + '%'
    # on PostGre SQL, it is ignoring lower case or upper case 
    @objects = Employee.where{ (name =~ query)  & (is_deleted.eq false) }.map{|x| {:name => x.name, :id => x.id }}
    
    respond_to do |format|
      format.html # show.html.erb 
      format.json { render :json => @objects }
    end
  end
  
  def edit
    @object = Employee.find_by_id params[:id] 
  end
  
  def update
    @object = Employee.find_by_id params[:id] 
    
    @object.update_attributes( params[:employee])
    @has_no_errors  = @object.errors.messages.length == 0
  end
  
  def destroy
    @object = Employee.find_by_id params[:id]
    @object.delete(current_user )
  end
end

