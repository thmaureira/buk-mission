Rails.application.routes.draw do
  root "home#index"
  get "up" => "rails/health#show", as: :rails_health_check

  # POC: "Ver como" switcher to try the permissions of each role.
  resource :session, only: :update

  # HR: balance tracking (R1, R4, R5, R9)
  resources :employees, only: [:index, :show] do
    member do
      get :summary
      get :movements
      get :settlement
    end
  end
end
