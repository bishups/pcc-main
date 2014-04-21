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
    @program.current_user = current_user

    #@program_types = ProgramType.all
    #@timings = []

    respond_to do |format|
      format.html
    end
  end

  def show
    @program = Program.find(params[:id].to_i)
    @program.current_user = current_user
    respond_to do |format|
      format.html
    end
  end

  def create
    @program = Program.new(params[:program])
    @program.current_user = current_user
    @program.proposer_id = current_user.id
    # Also update the start_date and end_date to start_date_time and end_date_time

    respond_to do |format|
      if @program.save
        @program.update_attributes :start_date => @program.start_date_time, :end_date => @program.end_date_time
        format.html { redirect_to @program, :notice => 'Program created successfully' }
      else
        format.html { render action: "new" }
        format.json { render json: @program.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @program = Program.find(params[:id])
    @program.current_user = current_user
    @trigger = params[:trigger]

    respond_to do |format|
      format.html
    end
  end

  def update
    @program = Program.find(params[:id])
    @program.current_user = current_user
    @trigger = params[:trigger]
    @program.feedback = params[:feedback] if params.has_key?(:feedback)
    @program.comments = params[:comments] if params.has_key?(:comments)

    respond_to do |format|
      format.html do
        if state_update(@program, @trigger)
          if @program.save!
            #redirect_to action: "edit" , :trigger => params[:trigger]
            redirect_to [@program]
          end
        else
          render :action => 'edit'
        end
      end
    end
  end

  def destroy
  end

  def update_timings
    # TODO - Need to update the slot times based on the program type selected
    # TODO - Keyword - cascaded drop down
    # TODO - Complications - 1. accessing formbuilder value from ajax, 2. multiple selection box
    # updates artists and songs based on program_type selected
    program_type = ProgramType.find(params[:program_type_id])
    # map to name and id for use in our options_for_select
    @timings = program_type.timings
    # @timings = program_type.timings.map{|a| [a.name, a.id]}.insert(0, "Select a Slot Time")
  end

  private

  def state_update(prog, trig)
    if Program::PROCESSABLE_EVENTS.include?(trig)
      prog.send(trig)
    end
  end

end
