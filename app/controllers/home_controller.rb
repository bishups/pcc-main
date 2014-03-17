class HomeController < ApplicationController
    before_filter :authenticate_user!

  def index

    # @programs = current_user.programs
    # @venues = current_user.venues
    @kits = current_user.kits
    @venues = current_user.venues
    @teachers = current_user.teachers
    @programs = current_user.programs
    # @teacher = current_user.teachers

    @pills = ["Programs","Venues","Kits","Teachers"]

  end

  def about
  end

  def registration_confirmation
  end
  
end
