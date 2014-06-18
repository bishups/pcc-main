class HomeController < ApplicationController
    before_filter :authenticate_user!, :except => [:registration_confirmation, :backdoor_login]

  def index

    # @programs = current_user.programs
    # @venues = current_user.venues
    # @kits = current_user.kits
    # @venues = current_user.venues
    # @teachers = current_user.teachers
    # @programs = current_user.programs
    # @teacher = current_user.teachers

    # @pills = ["Programs","Venues","Kits","Teachers"]
    @current_user = current_user
    @new_notifications = current_user.notification_logs.find_all_by_displayed(false)
  end

    def become
      return unless current_user.is?(:super_admin) or current_user.is?(:zonal_coordinator)
      if user =  User.find(params[:user][:id])
        sign_in(:user, user)
        redirect_to root_url # or user_root_url
      else
        flash[:alert] = "You are trying to login as #{params[:user][:email]}, but it is not a valid username / email. Please select proper username /  email."
        redirect_to root_url
      end
    end

  def about
  end

  def registration_confirmation
  end

  def backdoor_login
    @resource = User.new
  end
  
end
