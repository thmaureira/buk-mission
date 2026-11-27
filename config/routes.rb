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
    resources :leave_periods, only: [:new, :create]
    resources :adjustments, only: [:new, :create]
  end
  resources :leave_periods, only: [] do
    member { post :cancel }
  end
  resources :ledger_entries, only: [] do
    member { post :reverse }
  end

  # Employee and manager (R7, R8)
  get "mi-saldo", to: "my_balances#show", as: :my_balance
  get "equipo", to: "teams#show", as: :team

  # Part 2: configurable types and grants (R10, R11)
  resources :leave_types, path: "tipos", only: [:index, :new, :create, :edit, :update]
end
