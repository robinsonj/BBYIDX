module AuthenticatedSystem
  protected
    # Returns true or false if the user is logged in.
    # Preloads @current_user with the user model if they're logged in.
    def logged_in?
      !!current_user
    end

    # Accesses the current user from the session. 
    # Future calls avoid the database because nil is not equal to false.
    def current_user
      @current_user ||= (login_from_session || login_from_basic_auth || login_from_cookie) unless @current_user == false
    end

    # Store the given user id in the session.
    def current_user=(new_user)
      session[:user_id] = new_user ? new_user.id : nil
      @current_user = new_user || false
    end

    # Check if the user is authorized
    #
    # Override this method in your controllers if you want to restrict access
    # to only a few actions or if you want to check if the user
    # has the correct rights.
    #
    # Example:
    #
    #  # only allow nonbobs
    #  def authorized?
    #    current_user.login != "bob"
    #  end
    def authorized?
      logged_in?
    end

    # Filter method to enforce a login requirement.
    #
    # To require logins for all actions, use this in your controllers:
    #
    #   before_filter :login_required
    #
    # To require logins for specific actions, use this in your controllers:
    #
    #   before_filter :login_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_filter :login_required
    #
    def login_required(*return_to_args)
      logged_in? || access_denied("You must log in", return_to_args)
    end
    
    def admin_required(*return_to_args)
      permit?('admin') || access_denied("You must log in as an administrator", return_to_args)
    end
    
    def editor?
      if !%w(index new create).include?(params[:action]) && self.respond_to?(:current_object) && current_object
        @security_class = current_object.class
        permit?('editor of :current_object or editor of :security_class')
      else
        if self.respond_to?(:current_model)
          @security_class = current_model
        else
          @security_class = controller_name.singularize.camelize.constantize
        end
        permit?('editor of :security_class')
      end
    end
    
    def editor_required(*return_to_args)
      access_denied("You do not have the necessary privileges", return_to_args) unless editor?
    end

    # Redirect as appropriate when an access request fails.
    #
    # The default action is to redirect to the login screen.
    #
    # Override this method in your controllers if you want to have special
    # behavior in case the user is not authorized
    # to access the requested action.  For example, a popup window might
    # simply close itself.
    def access_denied(message, return_to_args)
      flash[:info] = "#{message} to #{request_as_words}."
      respond_to do |format|
        format.html do
          if ajax_request?
            store_location return_to_args
            render :template => 'generalized_redirect', :layout => false, :locals => { :redirect_path => login_url, :message => 'Logging in...' }
          else
            store_location return_to_args
            redirect_to login_path
          end
          format.any do
            store_location return_to_args
            redirect_to login_path
          end
        end
      end
    end

    # Store the URI of the current request in the session.
    #
    # We can return to this location by calling #redirect_back_or_default.
    #
    # Modified to store method (e.g. POST, GET) and params.
    def store_location(return_to_args = [])
      if return_to_args.empty?
        session[:return_to] = request.request_uri
        session[:return_to_method] = request.method
        session[:return_to_params] = CGI.parse(request.raw_post)
      else
        session[:return_to] = return_to_args[0]
        session[:return_to_method] = return_to_args[1].to_s || 'get'
        session[:return_to_params] = return_to_args[2] || {}
      end
    end

    # Redirect to the URI stored by the most recent store_location call or
    # to the passed default.
    #
    # Modified to handle POST, PUT, and other novel redirects.
    def redirect_back_or_default(default = nil, &default_block)
      if session[:return_to_method].nil? || session[:return_to_method] == 'get'
        if session[:return_to]
          redirect_to session[:return_to]
        elsif default
          redirect_to default
        else
          yield default_block
        end
      else
        flash.keep
        render :template => 'generalized_redirect',
          :locals => {
            :message => "Logging in. One moment please...",
            :redirect_path   => session[:return_to],
            :redirect_method => session[:return_to_method],
            :redirect_params => session[:return_to_params] }
        flash.keep
      end
      session[:return_to] = nil
      session[:return_to_method] = nil
      session[:return_to_params] = nil
    end

    # Inclusion hook to make #current_user and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_user, :editor?, :logged_in?
    end

    # Called from #current_user.  First attempt to login by the user id stored in the session.
    def login_from_session
      self.current_user = User.find_by_id(session[:user_id]) if session[:user_id]
    end

    # Called from #current_user.  Now, attempt to login by basic authentication information.
    def login_from_basic_auth
      authenticate_with_http_basic do |username, password|
        self.current_user = User.authenticate(username, password)
      end
    end

    # Called from #current_user.  Finaly, attempt to login by an expiring token in the cookie.
    def login_from_cookie
      # NB: We must only use the auto-login token on GET requests; doing otherwise exposes us to XSRF vulnerabilities.
      # http://weblog.rubyonrails.org/2011/2/8/csrf-protection-bypass-in-ruby-on-rails
      if request.method == :get
        user = cookies[:auth_token] && User.find_by_remember_token(cookies[:auth_token])
        if user && user.remember_token?
          cookies[:auth_token] = { :value => user.remember_token, :expires => user.remember_token_expires_at }
          self.current_user = user
        end
      end
    end
end
