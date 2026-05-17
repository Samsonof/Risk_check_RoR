Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "dashboard#index"

  get "cases/:id", to: "dashboard#case_panel", as: :case_panel
  get "score/:id", to: "dashboard#score", as: :score
end
