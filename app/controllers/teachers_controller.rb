class TeachersController < ApplicationController
  
  def index
    @teachers = User.all   # TODO: Filter by role

    respond_to do |format|
      format.html
    end
  end

  def show
    @teacher = User.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

end
