class ProgramsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @programs = Program.all

    respond_to do |format|
      format.html
    end
  end

  def show
  end

  def create
  end

  def update
  end

  def destroy
  end
end
