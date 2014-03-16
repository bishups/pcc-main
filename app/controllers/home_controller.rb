class HomeController < ApplicationController
  
  def index

    # @programs = current_user.programs
    # @venues = current_user.venues
    @kits = Kit.all
    # @teacher = current_user.teachers

    @pills = ["Programs","Venues","Kits","Teachers"]

  end

  def about
  end

  def registration_confirmation
  end
  
end
