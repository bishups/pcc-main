class TeachersController < ApplicationController
  
  def index
    @teachers = Teacher.all   # TODO: Filter by role

    respond_to do |format|
      format.html
    end
  end

  def show
    @teacher = Teacher.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

end
