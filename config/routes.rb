# frozen_string_literal: true

Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # API Routes
  namespace :api do
    namespace :v1 do
      # Authentication
      post 'register', to: 'stores#create'
      get 'reconciliation_rules', to: 'stores#reconciliation_rules'
      post 'reconciliation_rules', to: 'stores#update_reconciliation_rules'

      post 'login', to: 'sessions#create'
      delete 'logout', to: 'sessions#destroy'

      resources :reconciliations, only: [:index, :create]

      resources :transactions, only: [:index, :show] do
        collection do
          get :summary
          get :by_period
        end
      end

      resources :sales, only: [:index, :show] do
        collection do
          get :summary
        end
      end

      resources :wallets, only: [:index, :show] do
        member do
          get :transactions
        end
      end

      resource :profile, controller: 'stores', only: [:show, :update]
    end
  end
end
