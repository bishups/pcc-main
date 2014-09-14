PccMain::Application.routes.draw do

  resources :notification_logs
  resources :activity_logs


  resources :notifications


  #mount RailsAdminImport::Engine => '/rails_admin_import', :as => 'rails_admin_import'
  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'

  devise_for :users, :controllers => { :registrations => 'registrations', :omniauth_callbacks => "omniauth_callbacks" }

  # Misc. static pages
  get '/about'                            => 'home#about'
  get '/registration_confirmation'        => 'home#registration_confirmation'
  get '/backdoor_login'        => 'home#backdoor_login'
  get 'programs/update_timings', :as => 'update_program_timings'
  get 'programs/update_program_donations', :as => 'update_program_donations'
  get 'teacher_schedules/update_timings', :as => 'update_teacher_schedule_timings'
  get 'teacher_schedules/update_centers', :as => 'update_teacher_schedule_centers'
  get 'program_teacher_schedules/update_blockable_teachers', :as => 'update_program_teacher_schedule_blockable_teachers'
  get 'program_teacher_schedules/update_blockable_programs', :as => 'update_program_teacher_schedule_blockable_programs'
  get 'program_teacher_schedules/update_additional_comments', :as => 'update_program_teacher_schedule_additional_comments'
  get 'program_teacher_schedules/update_program_timings', :as => 'update_program_teacher_schedule_program_timings'


  get '/login_as_other_user' => "home#login_as"
  post '/login_as' => "home#become"
  get "/users/autocomplete" => "user#autocomplete_user_email"

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
    resources :teacher_schedules do
      member do
        get 'reserve'
      end
    end
    member do
      get 'comments'
    end
  end


  # Admin exclusive resources
  #namespace :admin do
  #  resources :users
  #end

  resources :notification_logs do
    collection do
      delete :delete_all
    end
  end

  root :to => 'home#index'

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
