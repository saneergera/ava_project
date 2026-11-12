Rails.application.routes.draw do
  # Upload page, migration history and migration details.
  resources :imports, only: [ :index, :new, :create, :show ]

  # Read-only list of the patients in the database.
  resources :patients, only: [ :index ]

  # The upload page is the home page.
  root "imports#new"

  # Returns 200 when the app is running. Used by Docker and uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check
end
