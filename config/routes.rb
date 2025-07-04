# frozen_string_literal: true

Rails.application.routes.draw do
  get "transactions/index"
  get "transactions/show"
  get "transactions/new"
  get "transactions/create"
  get "wallets/index"
  get "wallets/show"
  get "customers/index"
  get "customers/show"
  get "customers/new"
  get "customers/create"
  get "customers/edit"
  get "customers/update"
  get "customers/destroy"
  get "stores/index"
  get "stores/show"
  get "stores/new"
  get "stores/create"
  get "stores/edit"
  get "stores/update"
  get "stores/destroy"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Rutas para el sistema de conciliación
  resources :stores do
    member do
      get :transactions
      get :summary
    end
  end

  resources :customers do
    member do
      get :transactions
      get :summary
    end
  end

  resources :wallets, only: [:index, :show] do
    member do
      get :transactions
      get :summary
    end
  end

  resources :transactions, only: [:index, :show, :new, :create] do
    collection do
      get :summary
      get :by_period
    end
  end

  # Ruta para el dashboard principal
  root "stores#index"
end
