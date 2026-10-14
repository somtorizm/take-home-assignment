Rails.application.routes.draw do
  namespace :api do
    post '/auth/login', to: 'auth#login'
    post '/auth/signup', to: 'auth#signup'

    resources :products, only: [:index, :show]

    get '/cart', to: 'cart#show'
    post '/cart/items', to: 'cart#add_item'
    patch '/cart/items/:id', to: 'cart#update_item'
    delete '/cart/items/:id', to: 'cart#remove_item'
    post '/cart/promo_code', to: 'cart#apply_promo_code'
    delete '/cart/promo_code', to: 'cart#remove_promo_code'

    resources :orders, only: [:index, :create]
  end
end
