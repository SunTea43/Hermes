Rails.application.routes.draw do
  resources :inventory_movements
  resources :inventories
  resources :payments
  resources :sales_order_items
  resources :sales_orders
  resources :purchase_order_items
  resources :purchase_orders
  resources :product_prices
  resources :products
  resources :role_assignments
  resources :businesses
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "businesses#index"
end
