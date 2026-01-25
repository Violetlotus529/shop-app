Rails.application.routes.draw do
  devise_for :customers

  resources :products, only: %i[index show]

  resource :cart, only: [:show]
  resources :cart_items, only: %i[create update destroy]
  namespace :admin do
    resources :inventories, only: [:index]

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
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
