class ProgramsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @programs = Program.all

    respond_to do |format|
      format.html
    end
  end

  def new
    @program = Program.new

    respond_to do |format|
      format.html
    end
  end

  def show
    @program = Program.find(params[:id].to_i)
    
    respond_to do |format|
      format.html
    end
  end

  def create
    @program = Program.new(params[:program])
    @program.proposer_id = current_user.id

    respond_to do |format|
      if @program.save
        format.html { redirect_to @program, :notice => 'Program created successfully' }
      else
        format.html { render action: "new" }
        format.json { render json: @program.errors, status: :unprocessable_entity }
      end
    end
  end

  def announce
    @program = Program.find(params[:id])
    @program.announce! if @program.ready_for_announcement?

    respond_to do |format|
      format.html { redirect_to @program }
    end
  end

  def update
  end

  def destroy
  end
end
