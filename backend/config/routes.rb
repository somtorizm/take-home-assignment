Rails.application.routes.draw do
  namespace :api do
    post '/auth/login', to: 'auth#login'
    post '/auth/signup', to: 'auth#signup'

    resources :products, only: [:index, :show]

    get '/cart', to: 'cart#show'
    post '/cart/items', to: 'cart#add_item'
    patch '/cart/items/:id', to: 'cart#update_item'
    delete '/cart/items/:id', to: 'cart#remove_item'

    resources :orders, only: [:index, :create]
  end
end
