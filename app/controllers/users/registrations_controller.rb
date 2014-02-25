class Users::RegistrationsController < Devise::RegistrationsController

  before_filter :authenticate_user!, :only => [:edit, :update, :authorize_twitter]

  # def new
  #   super
  # end

  def create
    # if params[:first_user]
    #   if User.count > 0  # Critical line! Never set @first_user unless we've verified that this is really the first user.
    #     flash[:info] = 'An admin user has already been created.'
    #     redirect_to :action => :new
    #     return
    #   end
    #   @first_user = true
    # end

    # cookies.delete :auth_token
    # new_user_from_params
    # if @user.valid?
    #   @user.save!
    #   @user.register!
    #   @user.activate! if @user.linked_to_twitter? || @user.linked_to_facebook?
    #   promote_to_superuser if @first_user
    #   self.current_user = @user
    #   flash[:info] = render_to_string(:partial => 'created')
    #   #redirect_back_or_default('/')
    #   #send_account_state_notification @user
    #   super
    # else
    #   if @user.linked_to_twitter? || @user.linked_to_facebook?
    #     render :action => 'new_via_third_party'
    #   else
    #     render :action => 'new'
    #   end
    # end

    super
  end

protected

  def new_user_from_params
    @user = User.new(params[:user])
    @user.twitter_token = params[:user][:twitter_token]
    @user.twitter_secret = params[:user][:twitter_secret]
    @user.twitter_handle = params[:user][:twitter_handle]
    if FACEBOOK_ENABLED && current_facebook_user
      @user.facebook_name = params[:user][:facebook_name]
      @user.facebook_uid = current_facebook_user.id
      @user.facebook_access_token = current_facebook_client.access_token
    end
  end
end
