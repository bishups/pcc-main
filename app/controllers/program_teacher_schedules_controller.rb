class ProgramTeacherSchedulesController < ApplicationController
  before_filter :authenticate_user!
  #before_filter :load_program_teacher_schedule!

  def new
    @program_teacher_schedule = load_program_teacher_schedule!(params)
    @teachers = load_relevant_teachers()

    # @program_teacher_schedule.program = ::Program.find(params[:program_id])
    # @teacher_schedules = load_relevant_teacher_schedules()
    
    respond_to do |format|
      format.html do
        if request.xhr?
          render :layout => false
        end 
      end
    end
  end

  def create
    # TODO - add the logic for saving the program with the schedule, and splitting the teacher schedule

    if !params.has_key?(:program_teacher_schedule)
      # this was an update, which came to create, because of all the activerecord non-sense
      _update
    else
      error = block_teacher_schedule!(params[:program_teacher_schedule])
      @program_teacher_schedule = load_program_teacher_schedule!(params[:program_teacher_schedule])

      respond_to do |format|
        if error.empty?
          format.html {
            #redirect_to program_teacher_schedule_path(@program_teacher_schedule)
            redirect_to program_path(@program_teacher_schedule.program)
          }
        else
          format.html { render(:action => 'new') }
        end
      end

    end
  end


  # GET /program_teacher_schedules/1
  # GET /program_teacher_schedules/1.json
  def show
    @program_teacher_schedule = load_program_teacher_schedule!(params)
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @program_teacher_schedule }
    end

  end

  # GET /venues/1/edit
  def edit
    if flash[:program_teacher_schedule]
      @program_teacher_schedule = flash[:program_teacher_schedule]
    else
      @program_teacher_schedule = load_program_teacher_schedule!(params)
    end
    @trigger = params[:trigger]

  end


  # PUT /venues/1
  # PUT /venues/1.json
  def update
    _update
  end





  private

  def _update
    @program_teacher_schedule = load_program_teacher_schedule!(params)
    @trigger = params[:trigger]

=begin
    state_update(@program_teacher_schedule, @trigger)
    respond_to do |format|
      # need to go to the custom save
      if @program_teacher_schedule.update
        format.html { redirect_to @program_teacher_schedule, notice: 'Program Teacher Schedule was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @program_teacher_schedule.errors, status: :unprocessable_entity }
      end
    end
=end
    state_update(@program_teacher_schedule, @trigger)
    respond_to do |format|
      format.html do
        if @program_teacher_schedule.errors.empty? && @program_teacher_schedule.update
          if @program_teacher_schedule.program_id
            redirect_to program_teacher_schedule_path(:id => @program_teacher_schedule.teacher_schedule_id)
          else
            redirect_to  teacher_teacher_schedules_path(@program_teacher_schedule.teacher)
          end
          #format.html { redirect_to @teacher, notice: 'Teacher was successfully updated.' }
          #format.json { head :no_content }
        else
          #format.html { render action: "edit" }
          #format.json { render json: @teacher.errors, status: :unprocessable_entity }
          flash[:program_teacher_schedule] = @program_teacher_schedule
          redirect_to :action => :edit, :trigger => params[:trigger], :id => params[:id]
        end
      end
    end


  end

  #:blocked_by_user_id
  def load_program_teacher_schedule!(params)
    pts = ProgramTeacherSchedule.new
    pts.current_user = current_user
    if params.has_key?(:id)
      pts.teacher_schedule_id = (params[:id]).to_i
      pts.teacher_schedule = TeacherSchedule.find(pts.teacher_schedule_id)
      pts.state = pts.teacher_schedule.state
      pts.program_id = pts.teacher_schedule.program_id
      pts.program = Program.find(pts.teacher_schedule.program_id)
      pts.teacher_id = pts.teacher_schedule.teacher_id
      pts.teacher = Teacher.find(pts.teacher_schedule.teacher_id)
      pts.blocked_by_user_id = pts.teacher_schedule.blocked_by_user_id
    elsif params.has_key?(:program_id)
      pts.program = ::Program.find((params[:program_id]).to_i)
    end
    pts
  end


  def state_update(pts, trig)
    if ::ProgramTeacherSchedule::PROCESSABLE_EVENTS.include?(@trigger)
      pts.send(trig)
    end
  end

  # Incoming params - params => {"program_id"=>"3", "teacher_id"=>"1"}
  # 1. given the teacher_id, find the schedules relevant for the program_id
  # 2. split the schedule, marking the one against program - with program_id and state
  def block_teacher_schedule!(params)
    program = Program.find(params[:program_id])
    teacher = Teacher.find(params[:teacher_id])
    error = []
    program.timings.each {|t|
      ts = teacher.teacher_schedules.where('start_date <= ? AND end_date >= ? AND timing_id = ? AND state = ? AND center_id = ?',
                             program.start_date.to_date, program.end_date.to_date, t.id,
                             ::TeacherSchedule::STATE_AVAILABLE, program.center_id).first
      # split this schedule as per program dates
      ts.split_schedule!(program.start_date.to_date, program.end_date.to_date)
      # TODO - check if break if correct idea, we should rollback previous change(s) in this loop
      if !ts.errors.empty?
        error << ts.errors.full_messages
        break
      end
      ts.state = ::ProgramTeacherSchedule::STATE_BLOCKED
      ts.program_id = program.id
      ts.blocked_by_user_id = current_user.id
      ts.save(:validate => false)
      # TODO - check if break if correct idea, we should rollback previous change(s) in this loop
      if !ts.errors.empty?
        error << ts.errors.full_messages
        break
      end
    }
    error
  end

  def load_relevant_teachers
    return [] if @program_teacher_schedule.program.nil?

    program = @program_teacher_schedule.program
    # get all teachers for specific program type
    teacher_ids = ProgramTypesTeachers.find_all_by_program_type_id(program.program_type_id).map { |pts| pts[:teacher_id] }
    program.timings.each {|t|
      # if teacher is available for each of timing specified in the program for the specified center
      teacher_ids &= TeacherSchedule.where(['start_date <= ? AND end_date >= ? AND timing_id = ? AND state = ? AND center_id = ?',
                                         program.start_date.to_date, program.end_date.to_date, t.id,
                                         ::TeacherSchedule::STATE_AVAILABLE, program.center_id]).pluck(:teacher_id)
    }
    teachers = Teacher.find(teacher_ids)
  end

=begin
  def load_relevant_teacher_schedules
    return [] if @program_teacher_schedule.program.nil?

    program = @program_teacher_schedule.program
    teacher_s = TeacherSchedule.where(['start_date <= ? AND end_date >= ? AND slot = ?', 
      program.start_date, program.end_date, program.slot]).includes(:user)

    teacher_s.map {|e| e }
  end
=end

end
