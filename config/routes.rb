Rails.application.routes.draw do
  root to: 'postcodes#index'

  resources :postcodes, only: [:index] do
    post :check, on: :collection
  end
end
