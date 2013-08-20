module Admin
  class UsersController < AdminController
    EDITABLE_CLASSES = [Idea, Comment, User, LifeCycle, ClientApplication].freeze
    
    before_filter :set_body_class
    
    helper_method :editable_classes
    helper_method :is_editor?
    
    make_resourceful do
      actions :index, :edit, :update, :suspend, :unsuspend
      
      before :update do
        # User disallows auto population of some properties from forms, so we must handle them manually
        @user.admin = params[:user][:admin] == '1'
        @user.moderator = params[:user][:moderator]
        @user.life_cycle_steps = LifeCycleStep.find(params[:user][:life_cycle_step_ids] || [])
        
        editor_roles = params[:user][:editor] || {}
        EDITABLE_CLASSES.each do |edit_class|
          if @user.admin? && editor_roles[edit_class.name] == '1'
            @user.has_role 'editor', edit_class
          else
            @user.has_no_role 'editor', edit_class
          end
        end
        
        unless params[:invite_to].blank?
          @user.is_invitee_for Current.find(params[:invite_to])
        end
      end
    
      response_for :index do |format|
        format.html do
          if ajax_request?
            render :partial => 'index' 
          else
            render :action => 'index' 
          end
        end
      end
      
      response_for :update do
        flash[:info] = 'Changes saved.'
        redirect_to edit_admin_user_path(@user)
      end
    end
  
    def activate
      @user = current_object
      @user.activate!
      render :partial => 'admin/users/state'
    end
  
    def suspend
      @user = current_object
      @user.suspend!
      render :partial => 'admin/users/state'
    end
  
    def unsuspend
      @user = current_object
      @user.unsuspend!
      render :partial => 'admin/users/state'
    end
  
    include ResourceAdmin
  
  protected
    def index_query_options
      { :select => 
          "users.*,
           (select count(*) from roles_users, roles
                           where roles_users.user_id = users.id
                             and roles_users.role_id = roles.id
                             and roles.name = 'admin') > 0 as admin" }
    end
    
    def default_sort
      ['created_at', true]
    end
    
    def set_body_class
      @body_class = 'users'
    end
    
    def editable_classes
      EDITABLE_CLASSES
    end
    
    def is_editor?(edit_class)
      @user.has_role? 'editor', edit_class
    end
  end
end
