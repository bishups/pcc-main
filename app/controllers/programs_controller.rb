class ProgramsController < ApplicationController
  before_filter :authenticate_user!

  def index
    center_ids = current_user.accessible_center_ids
    @programs = Program.where("center_id IN (?) AND end_date > ?", center_ids, (Time.zone.now - 15.days.from_now)).all
    respond_to do |format|
      format.html
    end
  end

  def new
    @program = Program.new
    @program.current_user = current_user
    center_ids = current_user.accessible_center_ids(:center_scheduler)
    # TODO - sort it
    @centers = Center.where("id IN (?)", center_ids)
    #@program_types = ProgramType.all
    #@timings = []

    respond_to do |format|
      if @program.can_create? :any => true
        format.html # new.html.erb
        format.json { render json: @program }
      else
        format.html { redirect_to programs_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @program.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    @program = Program.find(params[:id].to_i)
    @program.current_user = current_user

    respond_to do |format|
      if @program.can_view?
        format.html # show.html.erb
        format.json { render json: @program }
      else
        format.html { redirect_to programs_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @program.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    @program = Program.new(params[:program])
    @program.current_user = current_user
    @program.proposer_id = current_user.id
    # Also update the start_date and end_date to start_date_time and end_date_time

    respond_to do |format|
      if @program.can_create?
        if @program.send(::Venue::EVENT_PROPOSE) && @program.save
          @program.update_attributes :start_date => @program.start_date_time, :end_date => @program.end_date_time
          format.html { redirect_to @program, :notice => 'Program created successfully' }
        else
          format.html { render action: "new" }
          format.json { render json: @program.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to programs_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @program.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @program = Program.find(params[:id])
    @program.current_user = current_user
    @trigger = params[:trigger]
    @comment_category = Comment.where('model IS ? AND action IS ?', 'Program', @trigger).pluck(:text)

    if !@program.can_update?
      format.html { redirect_to program_path(@program), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
      format.json { render json: @program.errors, status: :unprocessable_entity }
    end
  end

  def update
    @program = Program.find(params[:id])
    @program.current_user = current_user
    @trigger = params[:trigger]
    @program.feedback = params[:feedback] if params.has_key?(:feedback)
    @program.comments = params[:comments] if params.has_key?(:comments)

    respond_to do |format|
      if @program.can_update?
        if state_update(@program, @trigger) &&  @program.save!
          format.html { redirect_to @program, notice: 'Program was successfully updated.' }
          format.json { render json: @program }
        else
          format.html { render :action => 'edit' }
          format.json { render json: @program.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to program_path(@program), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @program.errors, status: :unprocessable_entity }
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
