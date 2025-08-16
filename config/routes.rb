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
  post "stores/create"
  get "stores/edit"
  get "stores/update"
  get "stores/destroy"

  get "up" => "rails/health#show", as: :rails_health_check

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

  root "stores#index"
end
