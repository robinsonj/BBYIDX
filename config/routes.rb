BBYIDX::Application.routes.draw do

  resources :ideas do
    member do
      post :assign
      post :subscribe
      post :unsubscribe
      get :unsubscribe
    end

    resources :comments # for new/create, idea-specific index
    resource :vote
  end

  resources :currents do
    member do
      post :subscribe
      post :unsubscribe
      get :unsubscribe
    end
  end

  resource :session do
    member do
      get :create_twitter
      get :create_facebook
    end
  end

  resource :user, :map
  resources :comments, :tags, :profiles

  match '/login'                              => 'sessions#new', :as              => :login
  match '/login/twitter'                      => 'sessions#new', :as              => :twitter_login
  match '/logout'                             => 'sessions#destroy', :as          => :logout
  match '/signup'                             => 'users#new', :as                 => :signup
  match '/ideas/search/*search'               => 'ideas#index', :as               => :idea_search
  match '/user/send_activation'               => 'users#send_activation', :as     => :send_activation
  match '/user/activate/:activation_code'     => 'users#activate', :as            => :activate
  match '/user/password/forgot'               => 'users#forgot_password', :as     => :forgot_password
  match '/user/password/forgot'               => 'users#send_password_reset', :as => :send_password_reset
  match '/user/password/new/:activation_code' => 'users#new_password', :as        => :password_reset
  match '/user/authorize/twitter'             => 'users#authorize_twitter', :as   => :authorize_twitter
  match '/:model/:id/inappropriate'           => 'inappropriate#flag', :as        => :flag_inappropriate

  # Pretty URLS: these must come after more specific routes
  match '/ideas/:id/:title'     => 'ideas#show', :as    => :idea_pretty
  match '/profiles/:id/:title'  => 'profiles#show', :as => :profile_pretty
  match '/currents/:id/:title'  => 'currents#show', :as => :current_pretty

  # OAuth stuff
  match '/oauth/test_request'   => 'oauth#test_request', :as  => :test_request
  match '/oauth/access_token'   => 'oauth#access_token', :as  => :access_token
  match '/oauth/request_token'  => 'oauth#request_token', :as => :request_token
  match '/oauth/authorize'      => 'oauth#authorize', :as     => :authorize
  match '/oauth'                => 'oauth#index', :as         => :oauth

##########

  # Admin interface

  # Rails 2
  # map.namespace :admin do |admin|
  #   admin.root :controller => 'home', :action => 'show'
  #   admin.resources :users, :member => { :suspend => :put, :unsuspend => :put, :activate => :put}
  #   admin.resources :comments
  #   admin.resources :tags
  #   admin.resources :ideas
  #   admin.resources :currents
  #   admin.resources :client_applications
  #   admin.resource :chronology
  #   admin.with_options :path_prefix => 'admin/life_cycles', :controller => 'life_cycles' do |life_cycle|
  #     life_cycle.life_cycles 'edit',                 :action => 'edit'
  #     life_cycle.connect     'create',               :action => 'create'       # can't use post for these two b/c InPlaceEdtitor...
  #     life_cycle.connect     ':id/step/create',      :action => 'create_step'  # ...can't post when htmlResponse is false
  #     life_cycle.connect     ':id/update/order',     :action => 'reorder',                  :conditions => { :method => :post }
  #     life_cycle.connect     ':id/update/name',      :action => 'set_life_cycle_name',      :conditions => { :method => :post }
  #     life_cycle.connect     ':id/delete',           :action => 'delete',                   :conditions => { :method => :delete }
  #     life_cycle.connect     'step/:id/update/name', :action => 'set_life_cycle_step_name', :conditions => { :method => :post }
  #     life_cycle.connect     'step/:id/delete',      :action => 'delete_step',              :conditions => { :method => :delete }
  #   end
  #   admin.similar_ideas 'ideas/similar/:similar_to', :controller => 'ideas', :action => 'index'
  #   admin.similar_comments 'comments/similar/:similar_to', :controller => 'comments', :action => 'index'
  #   admin.with_options :path_prefix => 'admin/bucket', :controller => 'buckets', :name_prefix => 'admin_bucket_' do |bucket|
  #     bucket.show        '',                :action => 'show'
  #     bucket.add_idea    'add/:idea_id',    :action => 'add_idea',    :conditions => { :method => :put }
  #     bucket.remove_idea 'remove/:idea_id', :action => 'remove_idea', :conditions => { :method => :delete }
  #   end
  #   admin.with_options :controller => 'ideas' do |dup|
  #     dup.compare_duplicates 'ideas/:id/link_duplicate/:other_id', :action => 'compare_duplicates', :conditions => { :method => :get }
  #     dup.link_duplicates    'ideas/:id/link_duplicate/:other_id', :action => 'link_duplicates',    :conditions => { :method => :post }
  #   end
  # end

  # Rails 3
  namespace :admin do
    root :to => 'home#show'
    resources :comments, :tags, :ideas, :currents, :client_applications
    resource :chronology

    resources :users do
      member do
        put :suspend
        put :unsuspend
        put :activate
      end
    end

    match 'ideas/similar/:similar_to' => 'ideas#index', :as => :similar_ideas
    match 'comments/similar/:similar_to' => 'comments#index', :as => :similar_comments
  end

##########

  # Top-level routes
  root :to => 'home#show'
  match '/home_nearby_ideas' => 'home#nearby_ideas', :as => :home_nearby_ideas

  match ':page' => 'home#show', :as => :home, :constraints => {:page => /about|contact|privacy-policy|terms-of-use/}

  # No default routes declared for security & tidiness. (They make all actions in every controller accessible via GET requests.)
end
