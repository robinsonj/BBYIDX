# Bbyidx::Application.routes.draw do
#   resources :ideas do
#     resources :comments  # for new/create, and idea-specific comment index
#     resource :vote
#   end
# 
#   resources :currents do
#     resources :ideas
#   end
# 
#   resource :user do
#     member do
#       get :disconnect
#     end
#   end
#   resource :session
#   resources :comments # for global comment list
#   resources :tags
#   resources :profiles
#   resource :map
#   
#   match '/login' => 'sessions#new', :as => :login
#   match '/logout' => 'sessions#destroy', :as => :logout
#   match '/signup' => 'users#new', :as => :signup
#   match '/ideas/search/*search' => 'ideas#index', :as => :idea_search
#   match '/user/send_activation' => 'users#send_activation', :as => :send_activation
#   match '/user/activate/:activation_code' => 'users#activate', :as => :activate
#   match '/user/password/forgot' => 'users#forgot_password', :as => :forgot_password, :via => get
#   match '/user/password/forgot' => 'users#send_password_reset', :as => :send_password_reset, :via => post
#   match '/user/password/new/:activation_code' => 'users#new_password', :as => :password_reset
#   match '/:model/:id/inappropriate' => 'inappropriate#flag', :as => :flag_inappropriate
#   match '/user/authorize_twitter' => 'users#authorize_twitter', :as => :authorize_twitter
#   
#   # Facebook stuff
#   
#   # map.connect '/fb/:action', :controller => 'fb_connect'
# 
#   # OAuth stuff
#   
#   match '/oauth/test_request' => 'oauth#test_request', :as => :test_request
#   match '/oauth/access_token' => 'oauth#access_token', :as => :access_token
#   match '/oauth/request_token' => 'oauth#request_token', :as => :request_token
#   match '/oauth/authorize' => 'oauth#authorize', :as => :authorize
#   match '/oauth' => 'oauth#index', :as => :oauth
#   
#   namespace :admin do
#     resources :users do
#       member do
#         put :activate
#         put :suspend
#         put :unsuspend
#       end
#     end
#     resources :comments
#     resources :tags
#     resources :ideas
#     resources :currents
#     resources :client_applications
#     match 'path_prefixadmin/life_cyclescontrollerlife_cycles' => '#index', :as => :with_options
#     match 'ideas/similar/:similar_to' => 'ideas#index', :as => :similar_ideas
#     match 'comments/similar/:similar_to' => 'comments#index', :as => :similar_comments
#     match 'name_prefixadmin_bucket_path_prefixadmin/bucketcontrollerbuckets' => '#index', :as => :with_options
#     match 'controllerideas' => '#index', :as => :with_options
#   end
# 
#   match '/' => 'home#show'
#   match ':page' => 'home#show', :as => :home, :page => /about|contact|privacy-policy|terms-of-use/
# end


# ActionController::Routing::Routes.draw do |map|
BBYIDX::Application.routes.draw do |map|
  map.resources :ideas, :member => { :assign => :post } do |idea|
    idea.resources :comments # for new/create, idea-specific index
    idea.resource :vote
  end

  map.resources :currents, :member => { :subscribe => :post, :unsubscribe => [:post, :get] } do |current|
    current.resources :ideas
  end
  map.resource :user
  map.resource :session, :member => {
    :create_twitter => :get,
    :create_facebook => :get
  }
  map.resources :comments # for global comment list
  map.resources :tags
  map.resources :profiles
  map.resource :map
  
  map.login               '/login',                              :controller => 'sessions', :action => 'new'
  map.twitter_login       '/login/twitter',                      :controller => 'sessions', :action => 'new_twitter'
  map.logout              '/logout',                             :controller => 'sessions', :action => 'destroy'
  map.signup              '/signup',                             :controller => 'users', :action => 'new'
  map.idea_search         '/ideas/search/*search',               :controller => 'ideas', :action => 'index'
  map.send_activation     '/user/send_activation',               :controller => 'users', :action => 'send_activation'
  map.activate            '/user/activate/:activation_code',     :controller => 'users', :action => 'activate'
  map.forgot_password     '/user/password/forgot',               :controller => 'users', :action => 'forgot_password',     :conditions => { :method => :get }
  map.send_password_reset '/user/password/forgot',               :controller => 'users', :action => 'send_password_reset', :conditions => { :method => :post }
  map.password_reset      '/user/password/new/:activation_code', :controller => 'users', :action => 'new_password'
  map.authorize_twitter   '/user/authorize/twitter',             :controller => 'users', :action => 'authorize_twitter'
  map.flag_inappropriate  '/:model/:id/inappropriate',           :controller => 'inappropriate', :action => 'flag'
  
  # Pretty URLS: these must come after more specific routes

  map.idea_pretty         '/ideas/:id/:title',                   :controller => 'ideas',    :action => 'show'
  map.profile_pretty      '/profiles/:id/:title',                :controller => 'profiles', :action => 'show'
  map.current_pretty      '/currents/:id/:title',                :controller => 'currents', :action => 'show'
  
  # OAuth stuff
  
  map.test_request '/oauth/test_request', :controller => 'oauth', :action => 'test_request'
  map.access_token '/oauth/access_token', :controller => 'oauth', :action => 'access_token'
  map.request_token '/oauth/request_token', :controller => 'oauth', :action => 'request_token'
  map.authorize '/oauth/authorize', :controller => 'oauth', :action => 'authorize'
  map.oauth '/oauth', :controller => 'oauth', :action => 'index'

  # Admin interface
  
  map.namespace :admin do |admin|
    admin.root :controller => 'home', :action => 'show'
    admin.resources :users, :member => { :suspend => :put, :unsuspend => :put, :activate => :put}
    admin.resources :comments
    admin.resources :tags
    admin.resources :ideas
    admin.resources :currents
    admin.resources :client_applications
    admin.resource :chronology
    admin.with_options :path_prefix => 'admin/life_cycles', :controller => 'life_cycles' do |life_cycle|
      life_cycle.life_cycles 'edit',                 :action => 'edit'
      life_cycle.connect     'create',               :action => 'create'       # can't use post for these two b/c InPlaceEdtitor...
      life_cycle.connect     ':id/step/create',      :action => 'create_step'  # ...can't post when htmlResponse is false
      life_cycle.connect     ':id/update/order',     :action => 'reorder',                  :conditions => { :method => :post }
      life_cycle.connect     ':id/update/name',      :action => 'set_life_cycle_name',      :conditions => { :method => :post }
      life_cycle.connect     ':id/delete',           :action => 'delete',                   :conditions => { :method => :delete }
      life_cycle.connect     'step/:id/update/name', :action => 'set_life_cycle_step_name', :conditions => { :method => :post }
      life_cycle.connect     'step/:id/delete',      :action => 'delete_step',              :conditions => { :method => :delete }
    end
    admin.similar_ideas 'ideas/similar/:similar_to', :controller => 'ideas', :action => 'index'
    admin.similar_comments 'comments/similar/:similar_to', :controller => 'comments', :action => 'index'
    admin.with_options :path_prefix => 'admin/bucket', :controller => 'buckets', :name_prefix => 'admin_bucket_' do |bucket|
      bucket.show        '',                :action => 'show'
      bucket.add_idea    'add/:idea_id',    :action => 'add_idea',    :conditions => { :method => :put }
      bucket.remove_idea 'remove/:idea_id', :action => 'remove_idea', :conditions => { :method => :delete }
    end
    admin.with_options :controller => 'ideas' do |dup|
      dup.compare_duplicates 'ideas/:id/link_duplicate/:other_id', :action => 'compare_duplicates', :conditions => { :method => :get }
      dup.link_duplicates    'ideas/:id/link_duplicate/:other_id', :action => 'link_duplicates',    :conditions => { :method => :post }
    end
  end
  
  # Top-level routes
  
  map.root :controller => 'home', :action => 'show'
  map.home_nearby_ideas '/home/nearby-ideas', :controller => 'home', :action => 'nearby_ideas'
  
  map.home ':page', :controller => 'home', :action => 'show', :page => /about|contact|privacy-policy|terms-of-use/
  
  # No default routes declared for security & tidiness. (They make all actions in every controller accessible via GET requests.)
end
