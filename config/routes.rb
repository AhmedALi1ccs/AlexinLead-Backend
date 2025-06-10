Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post 'auth/login', to: 'authentication#login'
      post 'auth/logout', to: 'authentication#logout'
      post 'auth/refresh', to: 'authentication#refresh'
      get 'auth/me', to: 'authentication#me'
      
      # User management
      resources :users, only: [:index, :show, :create, :update, :destroy] do
        member do
          patch :activate
          patch :deactivate
        end
      end
      
      # Items (physical inventory)
      resources :items do
        member do
          patch :dispose
        end
        collection do
          get :categories
          get :locations
        end
      end
      
      # Data records (legacy - keeping for compatibility)
      resources :data_records do
        member do
          get :download
          post :share
          delete :unshare
        end
        collection do
          get :shared
          get :search
        end
      end
      
      # Audit logs
      resources :access_logs, only: [:index, :show]
      
      # Health check
      get 'health', to: 'health#check'
    end
  end
end
