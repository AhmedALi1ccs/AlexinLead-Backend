Rails.application.routes.draw do
      
  namespace :api do
    namespace :v1 do
      
      # Authentication routes
      post 'auth/login', to: 'authentication#login'
      post 'auth/logout', to: 'authentication#logout'
      post 'auth/refresh', to: 'authentication#refresh'
      get 'auth/me', to: 'authentication#me'
      get 'equipment/availability_for_dates', to: 'equipment#availability_for_dates'
      patch 'auth/change_password', to: 'authentication#change_password'
      # User management
      resources :users, only: [:index, :show, :create, :update, :destroy] do
        member do
          patch :activate
          patch :deactivate
          patch :reset_password
        end
        collection do
          post :create_employee
        end
      end
      resources :screen_inventories, only: [] do
      resources :screen_maintenances, path: 'maintenances', only: [:create, :update, :destroy]
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

      resources :monthly_targets do
        collection do
          get :current_month
        end
      end
      
      # Recurring Expenses
      resources :recurring_expenses do
        member do
          post :generate_expenses
        end
        collection do
          post :generate_all_for_month
        end
      end
      
      # Enhanced Expenses
      resources :expenses do
        member do
          patch :approve
          patch :reject
        end
        collection do
          get :summary
          get :pending_approval
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

      # LED Screen Rental Routes
      # Orders
      resources :orders do
        member do
          patch :cancel
          patch :pay
          patch :update_payment

        end
        collection do
          get :location_suggestions
          get :calendar
          
        end
      end
      
      # Employees
      resources :employees do
        collection do
          get :availability
        end
      end
      
      # Companies (3rd Party Providers)
      resources :companies do
        member do
          patch :deactivate  
        end
        collection do
          get :stats
        end
      end
      
      # Screen Inventory
      resources :screen_inventory do
        collection do
          get :availability
          get :availability_by_dates
        end
      end
      
      # Equipment
      resources :equipment do
        get :availability_for_dates, on: :collection
        collection do
          get :availability
        end
      end
      

      
          namespace :finance do
        get :overview
        get :monthly_comparison
        get :revenue_breakdown
        get :dashboard_summary
        post :set_monthly_target
        get :profit_sharing_settings
        patch :profit_sharing_settings
        get :export_financial_report
      end
    end
  end
end
