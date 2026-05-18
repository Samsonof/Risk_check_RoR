Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "queue#index"

  get "auto_approved", to: "queue#auto_approved", as: :auto_approved

  resources :cases, only: [:show] do
    member do
      post :evaluate
      post :decide
    end
  end

  resource  :config, only: %i[show update] do
    post :reevaluate_all
  end

  resources :personas, only: [:create]
end
