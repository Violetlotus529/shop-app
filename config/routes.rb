Rails.application.routes.draw do
  get 'orders/show'
  devise_for :customers

  resources :products, only: %i[index show]
  resource :cart, only: [:show]
  resources :cart_items, only: %i[create update destroy]

  namespace :webhooks do
    post :stripe, to: "stripe#create"
  end

  resource :checkout, only: [:create]
  resources :orders, only: [:show]

  namespace :admin do
    resources :inventories, only: [:index]

    resources :orders, only: %i[index show] do
      patch :status, on: :member
    end

    namespace :api, defaults: { format: :json } do
      resources :inventories, only: [:index] do
        collection { put :bulk_update }
      end
    end

    resources :products do
      patch :deleted, on: :member
    end

    namespace :trash do
      resources :products, only: %i[index show]
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
