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

    #@program_types = ProgramType.all
    #@timings = []

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
    @program.send(::Program::EVENT_ANNOUNCE) if @program.ready_for_announcement?

    respond_to do |format|
      format.html { redirect_to @program }
    end
  end

  def drop
    @program = Program.find(params[:id])
    @program.send(::Program::EVENT_DROP)

    respond_to do |format|
      format.html { redirect_to @program }
    end
  end

  def edit
    @program = Program.find(params[:id])
    @trigger = params[:trigger]

    respond_to do |format|
      format.html
    end
  end

  def update
    @program = Program.find(params[:id])
    @trigger = params[:trigger]

    state_update(@program, @trigger)

    respond_to do |format|
      format.html { redirect_to @program }
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
