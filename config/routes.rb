Rails.application.routes.draw do
  root "home#index"
  get "up" => "rails/health#show", as: :rails_health_check

  # POC: selector "Ver como" para probar los permisos por rol.
  resource :session, only: :update

  # RRHH: seguimiento de saldos (R1, R4, R5, R9)
  resources :employees, only: [:index, :show] do
    member do
      get :summary
      get :movements
      get :settlement
    end
    resources :leave_periods, only: [:new, :create]
  end
  resources :leave_periods, only: [] do
    member { post :cancel }
  end
  resources :ledger_entries, only: [] do
    member { post :reverse }
  end
end
