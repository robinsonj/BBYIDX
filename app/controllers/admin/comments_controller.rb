module Admin
  class CommentsController < AdminController
    has_rakismet :only => [:create, :update]
    before_filter :set_body_class
    
    make_resourceful do
      actions :index, :edit, :update
    
      response_for :index do |format|
        format.html do
          if ajax_request?
            render :partial => 'index' 
          else
            render :action => 'index' 
          end
        end
      end
    
      response_for :update do |format|
        format.html do
          if ajax_request?
            render :text => 'OK'
          else
            flash[:info] = 'Changes saved.'
            redirect_to edit_admin_comment_path(@comment)
          end
        end
      end
    end
    
    include ResourceAdmin
    
  protected
    
    def default_sort
      if search_pending_moderation?
        ['inappropriate_flags', true]
      else
        ['comments.created_at', true]
      end
    end
  
    def set_body_class
      @body_class = 'comments'
    end
  end
end
