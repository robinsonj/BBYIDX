BBYIDX::Application.routes.draw do
  resources :ideas, :member => { :assign => :post } do
    resources :comments # for new/create, idea-specific index
    resource :vote
  end

  resources :currents do
    resources :ideas
  end
  resource :user, :member => { :disconnect => :get }
  resource :session, :member => {
    :create_twitter => :get,
    :create_facebook => :get
  }
  resources :comments # for global comment list
  resources :tags
  resources :profiles
  resource :map
                                              
  get  '/login'                              => 'sessions#new',              as: :login
  get  '/logout'                             => 'sessions#destroy',          as: :logout
  get  '/signup'                             => 'users#new',                 as: :signup
  get  '/ideas/search/*search'               => 'ideas#index',               as: :idea_search
  get  '/user/send_activation'               => 'users#send_activation',     as: :send_activation
  get  '/user/activate/:activation_code'     => 'users#activate',            as: :activate
  get  '/user/password/forgot'               => 'users#forgot_password',     as: :forgot_password
  post '/user/password/forgot'               => 'users#send_password_reset', as: :send_password_reset
  get  '/user/password/new/:activation_code' => 'users#new_password',        as: :password_reset
  get  '/:model/:id/inappropriate'           => 'inappropriate#flag',        as: :flag_inappropriate
  get  '/user/authorize_twitter'             => 'users#authorize_twitter',   as: :authorize_twitter

  # Facebook stuff
  
  # connect '/fb/:action', :controller => 'fb_connect'

  get '/ideas/:id/:title',    to: 'ideas#show',    as: :idea_pretty   
  get '/profiles/:id/:title', to: 'profiles#show', as: :profile_pretty
  get '/currents/:id/:title', to: 'currents#show', as: :current_pretty
  
  # OAuth stuff
  
  get '/oauth/test_request' => 'oauth#test_request', as: :test_request
  get '/oauth/access_token' => 'oauth#access_token', as: :access_token
  get '/oauth/request_token' => 'oauth#request_token', as: :request_token
  get '/oauth/authorize' => 'oauth#authorize', as: :authorize
  get '/oauth' => 'oauth#index', as: :oauth

  # Admin interface
  
  namespace :admin do
    root :controller => 'home', :action => 'show'
    resources :users, :member => { :suspend => :put, :unsuspend => :put, :activate => :put}
    resources :comments
    resources :tags
    resources :ideas
    resources :currents
    resources :client_applications
    resource :chronology
    
    scope '/life_cycles' do
      get    'edit' => 'life_cycles#edit',  as: :life_cycles
      get    'create',               to: 'life_cycles#create'       # can't use post for these two b/c InPlaceEdtitor...
      get    ':id/step/create',      to: 'life_cycles#create_step'  # ...can't post when htmlResponse is false
      post   ':id/update/order',     to: 'life_cycles#reorder'
      post   ':id/update/name',      to: 'life_cycles#set_life_cycle_name'
      delete ':id/delete',           to: 'life_cycles#delete'
      post   'step/:id/update/name', to: 'life_cycles#set_life_cycle_step_name'
      delete 'step/:id/delete',      to: 'life_cycles#delete_step'
    end
    
    get 'ideas/similar/:similar_to' => 'ideas#index', as: :similar_ideas
    get 'comments/similar/:similar_to' => 'comments#index', as: :similar_comments
    
    scope '/bucket' do
      get    '',                to: 'buckets#show',        as: :bucket_show
      put    'add/:idea_id',    to: 'buckets#add_idea',    as: :bucket_add_idea
      delete 'remove/:idea_id', to: 'buckets#remove_idea', as: :bucket_remove_idea
    end
    
    get  'ideas/:id/link_duplicate/:other_id', to: 'ideas#compare_duplicates', as: :compare_duplicates
    post 'ideas/:id/link_duplicate/:other_id', to: 'ideas#link_duplicates',    as: :link_duplicates
  end
  
  # Top-level routes
  
  root :controller => 'home', :action => 'show'
  get '/home/nearby-ideas' => 'home#nearby_ideas', as: :home_nearby_ideas
  get ':page' => 'home#show', :page => /about|contact|privacy-policy|terms-of-use/, as: :home
  
  # No default routes declared for security & tidiness. (They make all actions in every controller accessible via GET requests.)
end
