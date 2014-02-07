# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  
  before_filter :oauth_required, :except => [:index, :show], :if => :xml_request?
  before_filter :add_ideas_feed
  before_filter :update_facebook_access_token

  include AuthenticatedSystem
  include PrettyUrlHelper
  include Facebooker2::Rails::Controller if FACEBOOK_ENABLED
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '6d2e62cd0d223411d020b5a2c2fdfe2d'
  
  def protect_against_forgery?
    super && !xml_request?  # no XSRF protection when using API; OAuth request signing accomplishes the same thing
  end
  
  def page_title
    nil
  end
  helper_method :page_title
  
  # See ActionController::Base for details 
  # This filters the contents of submitted sensitive data parameters
  # from the application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password, :password_confirmation
  
protected
  
  # Only allow publicly editable fields, so that for example user cannot hack idea rating
  def self.param_accessible(accessible_params)
    before_filter do |controller|
      accessible_params.each do |key, accessible_fields|
        accessible_fields = accessible_fields.map{ |f| f.to_s }
        if controller.params[key]
          controller.params[key].reject! do |param, value|
            !accessible_fields.include?(param)
          end
        end
      end
    end
  end
  
  def redirect_to(*args)
    flash.keep
    super(*args)
  end
  
  # Displays a graceful message for ideas that have been hidden or marked as spam
  def resource_gone(resource_name = nil)
    resource_name ||= controller_name.singularize
    render :template => '/gone', :status => 410, :locals => { :resource_name => resource_name }
  end
  
  # Returns a description of the active request as a verb phrase, such as "create a new idea" or "view users."
  # Used for creating titles and error messages.
  def request_as_words
    verb = case params[:action]
      when /new|create/
        'create new'
      when /edit|update|delete/
        'edit'
      when /show|index/
        'view'
      else
        'use'
    end
    "#{verb} #{controller_name.gsub('_',' ')}"
  end
  
  # Initializes the list of associated RSS feeds for a page, and add the default main feed.
  # Controllers may add other feeds by appending them to @feeds.
  def add_ideas_feed
    @ideas_rss_url = ideas_url(:format => 'rss')
    @feeds ||= []
    @feeds << { :href => @ideas_rss_url, :title => "#{LONG_SITE_NAME} New Ideas RSS Feed" }
  end
  
  def xml_request?
    request.format == :xml
  end
  
  def update_facebook_access_token
    if FACEBOOK_ENABLED
      # Facebook regularly expires its access tokens. We have client-side JS that checks for a new access token,
      # and places it in a cookie. We then check that cookie here on the server, via current_facebook_*, and
      # save the new access token if it has changed.
      if logged_in? && current_facebook_user && current_user.facebook_uid == current_facebook_user.id
        current_user.facebook_access_token = current_facebook_client.access_token
        current_user.save! if current_user.facebook_access_token_changed?
      end
    end
  end
  
end
