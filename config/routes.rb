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

  match '/login'                              => 'sessions#new',                :as => :login
  match '/login/twitter'                      => 'sessions#new',                :as => :twitter_login
  match '/logout'                             => 'sessions#destroy',            :as => :logout
  match '/signup'                             => 'users#new',                   :as => :signup
  match '/ideas/search/*search'               => 'ideas#index',                 :as => :idea_search
  match '/user/send_activation'               => 'users#send_activation',       :as => :send_activation
  match '/user/activate/:activation_code'     => 'users#activate',              :as => :activate
  match '/user/password/forgot'               => 'users#forgot_password',       :as => :forgot_password
  match '/user/password/forgot'               => 'users#send_password_reset',   :as => :send_password_reset
  match '/user/password/new/:activation_code' => 'users#new_password',          :as => :password_reset
  match '/user/authorize/twitter'             => 'users#authorize_twitter',     :as => :authorize_twitter
  match '/:model/:id/inappropriate'           => 'inappropriate#flag',          :as  => :flag_inappropriate

  # Pretty URLS: these must come after more specific routes
  match '/ideas/:id/:title'     => 'ideas#show',    :as => :idea_pretty
  match '/profiles/:id/:title'  => 'profiles#show', :as => :profile_pretty
  match '/currents/:id/:title'  => 'currents#show', :as => :current_pretty

  # OAuth stuff
  match '/oauth/test_request'   => 'oauth#test_request',  :as => :test_request
  match '/oauth/access_token'   => 'oauth#access_token',  :as => :access_token
  match '/oauth/request_token'  => 'oauth#request_token', :as => :request_token
  match '/oauth/authorize'      => 'oauth#authorize',     :as => :authorize
  match '/oauth'                => 'oauth#index',         :as => :oauth

  # Admin interface

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

    scope '/life_cycle', :path_prefix => 'admin/life_cycles' do
      match   'edit'                  => 'life_cycles#edit',                      :as => :life_cycles
      match   'create'                => 'life_cycles#create',                    :as => :connect # can't use post for these two b/c InPlaceEdtitor...
      match   ':id/step/create'       => 'life_cycles#create_step',               :as => :connect # ...can't post when htmlResponse is false
      post    ':id/update/order'      => 'life_cycles#reorder',                   :as => :connect
      post    ':id/update/name'       => 'life_cycles#set_life_cycle_name',       :as => :connect
      delete  ':id/delete'            => 'life_cycles#delete',                    :as => :connect
      post    'step/:id/update/name'  => 'life_cycles#set_life_cycle_step_name',  :as => :connect
      delete  'step/:id/delete'       => 'life_cycles#delete_step',               :as => :connect
    end

    match 'ideas/similar/:similar_to'     => 'ideas#index',     :as => :similar_ideas
    match 'comments/similar/:similar_to'  => 'comments#index',  :as => :similar_comments

    scope '/bucket',:name_prefix => 'admin_bucket_', :path_prefix => 'admin/bucket' do
      match   ''                => 'buckets#show',        :as => :show
      put     'add/:idea_id'    => 'buckets#add_idea',    :as => :add_idea
      delete  'remove/:idea_id' => 'buckets#remove_idea', :as => :remove_idea
    end

    scope '/dup' do
      get   'ideas/:id/link_duplicate/:other_id' => 'ideas#compare_duplicates', :as => :compare_duplicates
      post  'ideas/:id/link_duplicate/:other_id' => 'ideas#link_duplicates',    :as => :link_duplicates
    end
  end

  # Top-level routes
  root :to => 'home#show'
  match '/home_nearby_ideas' => 'home#nearby_ideas', :as => :home_nearby_ideas

  match ':page' => 'home#show', :as => :home, :constraints => {:page => /about|contact|privacy-policy|terms-of-use/}

  # No default routes declared for security & tidiness. (They make all actions in every controller accessible via GET requests.)
end
