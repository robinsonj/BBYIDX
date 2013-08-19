require File.expand_path('../boot', __FILE__)

require 'rails/all'
require './config/bbyidx_customization'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module BBYIDX
  class Application < Rails::Application
    config.assets.enabled = false  #! for now
    
    config.autoload_paths += %W(
      #{config.root}/lib
    )
    config.encoding = "utf-8"
    config.filter_parameters += [:password, :password_confirmation]
    config.active_support.escape_html_entities_in_json = true
    
    # This would be a good idea:
    # config.active_record.whitelist_attributes = true

    config.time_zone = 'UTC'
  
    # Your secret key for verifying cookie session data integrity.
    # If you change this key, all old sessions will become invalid!
    # Make sure the secret is at least 30 characters and all random, 
    # no regular words or you'll be exposed to dictionary attacks.
    config.session_store(
      :session_key => BBYIDX::SESSION_KEY,
      :secret      => BBYIDX::SESSION_SECRET)
  
    # Use the database for sessions instead of the cookie-based default,
    # which shouldn't be used to store highly confidential information
    # (create the session table with "rake db:sessions:create")
    # config.action_controller.session_store = :active_record_store
  
    # Use SQL instead of Active Record's schema dumper when creating the test database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql
  
    # Activate observers that should always be running
    # config.active_record.observers = :cacher, :garbage_collector
    config.active_record.observers = :user_observer, :idea_observer
    
    # disable forgery proction so that facebook works (we might be able to disble this only for the facebook controller)
    # config.action_controller.allow_forgery_protection = false
  end
end
