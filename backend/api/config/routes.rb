Rails.application.routes.draw do
  post "auth/login", to: "auth#login"
  resource :account, only: [:destroy]
  resources :users, only: [:create]
  resources :receipts, only: [:create]
  resources :products, only: [:index]
  get "products/:id/prices", to: "product_prices#show", as: :product_prices

  resources :shopping_lists do
    member do
      get :store_rankings
    end
    resources :items, controller: "shopping_list_items", only: [:index, :create, :update, :destroy]
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
