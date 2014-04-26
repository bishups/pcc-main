PccMain::Application.routes.draw do

  resources :notifications


  #mount RailsAdminImport::Engine => '/rails_admin_import', :as => 'rails_admin_import'
  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'

  devise_for :users, :controllers => { :registrations => 'registrations', :omniauth_callbacks => "omniauth_callbacks" }

  # Misc. static pages
  get '/about'                            => 'home#about'
  get '/registration_confirmation'        => 'home#registration_confirmation'
  get 'programs/update_timings', :as => 'update_timings'

  # Resources
  resources :enquiries
  resources :programs
  resources :program_teacher_schedules
  
  #resources :venues do
  #  resources :venue_schedules
  #end

  resources :venues
  resources :kits
  resources :venue_schedules
  resources :kit_schedules do
    member do
      get 'reserve'
    end
  end

  resources :teachers do
    resources :teacher_schedules
  end


  # Admin exclusive resources
  #namespace :admin do
  #  resources :users
  #end

  root :to => 'home#index'

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
