class HomeController < ApplicationController
    before_filter :authenticate_user!

  def index

    # @programs = current_user.programs
    # @venues = current_user.venues
    @kits = Kit.all
    @venues = Venue.all
    @teachers = Teacher.all
    @programs = Program.all
    # @teacher = current_user.teachers

    @pills = ["Programs","Venues","Kits","Teachers"]

  end

  def about
  end

  def registration_confirmation
  end
  
end
