# class UsersController < ApplicationController
#   include AuthenticatedSystem

#   before_filter :authenticate_user!, :only => [:edit, :update, :authorize_twitter]
#   before_filter :populate_user, :except => [:show]

#   def new
#     if params[:user] && params[:user][:twitter_token] || params[:facebook_create]
#       new_user_from_params
#       @user.tweet_ideas = @user.linked_to_twitter?
#       @user.facebook_post_ideas = @user.linked_to_facebook?
#       render :action => 'new_via_third_party'
#     else
#       @first_user = (User.count == 0)
#       render :action => 'new'
#     end
#   end

#   def create
#     if params[:first_user]
#       if User.count > 0  # Critical line! Never set @first_user unless we've verified that this is really the first user.
#         flash[:info] = 'An admin user has already been created.'
#         redirect_to :action => :new
#         return
#       end
#       @first_user = true
#     end

#     cookies.delete :auth_token
#     new_user_from_params
#     if @user.valid?
#       @user.save!
#       @user.register!
#       @user.activate! if @user.linked_to_twitter? || @user.linked_to_facebook?
#       promote_to_superuser if @first_user
#       self.current_user = @user
#       flash[:info] = render_to_string(:partial => 'created')
#       redirect_back_or_default('/')
#       send_account_state_notification @user
#     else
#       if @user.linked_to_twitter? || @user.linked_to_facebook?
#         render :action => 'new_via_third_party'
#       else
#         render :action => 'new'
#       end
#     end
#   end

#   def activate
#     if log_in_with_activation_code
#       flash[:info] = "Your account is now activated!"
#       redirect_back_or_default('/')
#     else
#       render :action => 'bad_activation_code'
#     end
#   end

#   def send_activation
#     @user = User.find_by_email(params[:email])
#     raise "No such user" unless @user
#     @user.reset_activation_code unless @user.activation_code
#     UserMailer.signup_notification(@user).deliver
#     flash[:info] = render_to_string(:partial => 'created')
#     redirect_back_or_default('/')
#   end

#   def forgot_password
#   end

#   def send_password_reset
#     if params[:email].blank?
#       @missing = true
#     else
#       user = User.find_by_email(params[:email])
#       if user
#         user.reset_activation_code
#         user.save!
#         UserMailer.password_reset(user).deliver
#         return render(:action => 'password_reset_sent')
#       else
#         @not_found = true
#       end
#     end
#     render :action => 'forgot_password'
#   end

#   def new_password
#     if log_in_with_activation_code
#       flash[:info] = "Please choose a new password."
#       redirect_to :action => 'edit'
#     else
#       render :action => 'bad_activation_code'
#     end
#   end

#   def edit
#     render :action => 'edit'
#   end

#   def update
#     # TODO: Should we require confirmation process if email changes?
#     @user.update_attributes(params[:user])
#     @user.unlink_twitter  if !params[:unlink_twitter].blank?
#     @user.unlink_facebook if !params[:unlink_facebook].blank?

#     if !params[:link_facebook].blank?
#       authorize_facebook
#     elsif @user.save
#       flash.now[:info] = "Your changes have been saved."
#       @user.password = @user.password_confirmation = nil

#       if !params[:link_twitter].blank?
#         redirect_to twitter_auth_request_url(authorize_twitter_url)
#         return
#       end
#     end

#     render :action => 'edit'
#   end

#   def authorize_twitter
#     credentials = verify_twitter_authorization
#     if credentials
#       @user.twitter_token = twitter_oauth.access_token.token
#       @user.twitter_secret = twitter_oauth.access_token.secret
#       @user.twitter_handle = credentials.screen_name
#       @user.tweet_ideas = true

#       if @user.save
#         flash.now[:info] = "Your IdeaX account is now linked to Twitter."
#       end
#     else
#       flash.now[:info] = "Twitter authorization canceled."
#     end

#     redirect_to edit_user_path
#   end

#   def authorize_facebook
#     if current_facebook_user
#       # The synchronous call to Mogli::User.find also serves to sanity check our access credentials
#       @user.facebook_name = Mogli::User.find("me", current_facebook_client).name
#       @user.facebook_uid = current_facebook_user.id
#       @user.facebook_access_token = current_facebook_client.access_token
#       @user.facebook_post_ideas = true

#       if @user.save
#         flash.now[:info] = "Your IdeaX account is now linked to Facebook."
#       end
#     else
#       flash.now[:info] = "Facebook authorization canceled."
#     end
#   end

#   def page_title
#     "Account Management"
#   end

#   include TwitterHelper

# protected

#   def populate_user
#     @user = current_user
#   end

#   def new_user_from_params
#     @user = User.new(params[:user])
#     @user.twitter_token = params[:user][:twitter_token]
#     @user.twitter_secret = params[:user][:twitter_secret]
#     @user.twitter_handle = params[:user][:twitter_handle]
#     if FACEBOOK_ENABLED && current_facebook_user
#       @user.facebook_name = params[:user][:facebook_name]
#       @user.facebook_uid = current_facebook_user.id
#       @user.facebook_access_token = current_facebook_client.access_token
#     end
#   end

#   def log_in_with_activation_code
#     unless params[:activation_code].blank?
#       code = params[:activation_code].gsub(/[^\w]/, '')  # Remove any whitespace/garbage the user accidentally copied
#       self.current_user = User.find_by_activation_code(code)
#       if logged_in? && !current_user.active?
#         current_user.activate!
#         send_account_state_notification current_user
#       end
#     end
#     logged_in?
#   end

#   def send_account_state_notification(user)
#     if user.active?
#       UserMailer.activation(user).deliver
#     elsif user.pending?
#       UserMailer.signup_notification(user).deliver if user.activation_code
#     end
#   end

# private

#   def promote_to_superuser
#     raise "Not first user" if User.find(:all) != [@user]   # extra sanity check to prevent security hole

#     @user.activate!
#     @user.has_role 'admin'
#     @user.has_role 'editor', User
#     @user.has_role 'editor', Idea
#     @user.has_role 'editor', Comment
#     @user.has_role 'editor', Current
#     @user.has_role 'editor', LifeCycle
#     @user.has_role 'editor', ClientApplication
#   end

# end
