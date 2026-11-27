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
  resources :grant_batches, path: "cargas", only: [:index, :new, :create, :show]

  # Migration from Excel (R6)
  resources :opening_balance_imports, path: "migracion", only: [:index, :new, :create, :show] do
    member do
      post :approve
      post :reject
    end
  end

  # Scheduled jobs (R2, R3, R11): manual run to show idempotency
  get "procesos", to: "scheduled_jobs#index", as: :scheduled_jobs
  post "procesos/:job", to: "scheduled_jobs#run", as: :run_scheduled_job

  # Usage metrics: visits and actions recorded by TracksPageViews
  get "metricas", to: "metrics#show", as: :metrics
end
