PccMain::Application.routes.draw do

  devise_for :users, :controllers => { :registrations => 'registrations' }

  # Misc. static pages
  get '/about'                            => 'home#about'
  get '/registration_confirmation'        => 'home#registration_confirmation'

  # Admin exclusive resources
  namespace :admin do
    resources :users
  end

  root :to => 'home#index'

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
