module Admin
  class ClientApplicationsController < AdminController
    before_filter :editor_required, :except => [] # Even read operations require editor privileges, because API secrets should be protected
    before_filter :set_body_class
  
    make_resourceful do
      actions :index, :show, :new, :create, :edit, :update, :destroy
      
      response_for :index do |format|
        format.html do
          if ajax_request?
            render :partial => 'index' 
          else
            render :action => 'index' 
          end
        end
      end
    end
    
    include ResourceAdmin
    
  protected
    
    def default_sort
      ['name', true]
    end
  
    def set_body_class
      @body_class = 'client-apps'
    end
  end
end
