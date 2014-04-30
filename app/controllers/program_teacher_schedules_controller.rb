class ProgramTeacherSchedulesController < ApplicationController
  before_filter :authenticate_user!
  #before_filter :load_program_teacher_schedule!

  def new
    @program_teacher_schedule = load_program_teacher_schedule!(params)
    @teachers = load_relevant_teachers()

    # @program_teacher_schedule.program = ::Program.find(params[:program_id])
    # @teacher_schedules = load_relevant_teacher_schedules()

    respond_to do |format|
      if @program_teacher_schedule.can_create?
        format.html
        # format.html {render :layout => false}  if request.xhr?
        format.json { render json: @program_teacher_schedule }
      else
        format.html { redirect_to program_path( params[:program_id]), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @program_teacher_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    if !params.has_key?(:program_teacher_schedule)
      # this was an update, which came to create, because of all the activerecord non-sense
      _update
    else
      @program_teacher_schedule = load_program_teacher_schedule!(params[:program_teacher_schedule])
      if !@program_teacher_schedule.can_create?
        respond_to do |format|
          format.html { redirect_to program_path( params[:program_id]), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
          format.json { render json: @program_teacher_schedule.errors, status: :unprocessable_entity }
        end
      else
        error = block_teacher_schedule!(@program_teacher_schedule, params[:program_teacher_schedule])
        #@program_teacher_schedule = load_program_teacher_schedule!(params[:program_teacher_schedule])
        respond_to do |format|
          if error.empty?
            format.html { redirect_to program_teacher_schedule_path(:id => @program_teacher_schedule.teacher_schedule_id), notice: 'Program-Teacher Schedule was successfully updated.'  }
            format.json { render :json => @program_teacher_schedule }

            #format.html { redirect_to program_path(@program_teacher_schedule.program) }
            #format.json { render json: @program_teacher_schedule, status: :created, location: @program_teacher_schedule }
          else
            @teachers = load_relevant_teachers()
            format.html { render action: "new" }
            format.json { render json: error, status: :unprocessable_entity }
          end
        end
      end
    end
  end


  # GET /program_teacher_schedules/1
  # GET /program_teacher_schedules/1.json
  def show
    @program_teacher_schedule = load_program_teacher_schedule!(params)

    respond_to do |format|
      if @program_teacher_schedule.can_update?
        format.html # show.html.erb
        format.json { render json: @program_teacher_schedule }
      else
        format.html { redirect_to teacher_teacher_schedules_path(@program_teacher_schedule.teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @program_teacher_schedule.errors, status: :unprocessable_entity }
      end
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
    @program_teacher_schedule.comment_category = Comment.where('model IS ? AND action IS ?', 'ProgramTeacherSchedule', @trigger).pluck(:text)

    unless @program_teacher_schedule.can_update?
      format.html { redirect_to teacher_teacher_schedules_path(@program_teacher_schedule.teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
      format.json { render json: @program_teacher_schedule.errors, status: :unprocessable_entity }
    end
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
    @program_teacher_schedule.load_comments!(params)

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

    respond_to do |format|
      if @program_teacher_schedule.can_update?
        if state_update(@program_teacher_schedule, @trigger) &&  @program_teacher_schedule.update(@trigger)
          if @program_teacher_schedule.program_id
            format.html { redirect_to program_teacher_schedule_path(:id => @program_teacher_schedule.teacher_schedule_id), notice: 'Program-Teacher Schedule was successfully updated.'  }
            format.json { render :json => @program_teacher_schedule }
          else
            format.html { redirect_to  teacher_teacher_schedules_path(@program_teacher_schedule.teacher) }
            format.json { render :json => @program_teacher_schedule }
          end
        else
          flash[:program_teacher_schedule] = @program_teacher_schedule
          format.html { redirect_to :action => :edit, :trigger => params[:trigger], :id => params[:id]}
          format.json { render json: @program_teacher_schedule.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to teacher_teacher_schedules_path(@program_teacher_schedule.teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @program_teacher_schedule.errors, status: :unprocessable_entity }
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
      pts.teacher.current_user = current_user
      pts.blocked_by_user_id = pts.teacher_schedule.blocked_by_user_id
    elsif params.has_key?(:program_id)
      pts.program = ::Program.find((params[:program_id]).to_i)
    end
    pts
  end


  def state_update(pts, trig)
    pts.current_user = current_user
    if ::ProgramTeacherSchedule::PROCESSABLE_EVENTS.include?(@trigger)
      pts.send(trig)
    end
  end

  # Incoming params - params => {"program_id"=>"3", "teacher_id"=>"1"}
  # 1. given the teacher_id, find the schedules relevant for the program_id
  # 2. split the schedule, marking the one against program - with program_id and state
  def block_teacher_schedule!(pts, params)
    program = Program.find(params[:program_id])
    teacher = Teacher.find(params[:teacher_id])
    error = []
    program.timings.each {|t|
      ts = teacher.teacher_schedules.where('start_date <= ? AND end_date >= ? AND timing_id = ? AND state = ? AND center_id = ? AND program_type_id IS ?',
                             program.start_date.to_date, program.end_date.to_date, t.id,
                             ::TeacherSchedule::STATE_AVAILABLE, program.center_id, program.program_type_id).first
      # split this schedule as per program dates
      ts.split_schedule!(program.start_date.to_date, program.end_date.to_date)
      # TODO - check if break if correct idea, we should rollback previous change(s) in this loop
      if !ts.errors.empty?
        error << ts.errors.full_messages
        break
      end
      ts.program_id = program.id
      ts.blocked_by_user_id = current_user.id
      ts.state = ::ProgramTeacherSchedule::STATE_BLOCKED
      ts.clear_comments!
      # This is a hack to store the last update
      ts.store_last_update!(current_user, ::ProgramTeacherSchedule::STATE_UNKNOWN, ::ProgramTeacherSchedule::STATE_BLOCKED, ::ProgramTeacherSchedule::EVENT_BLOCK)
      #ts.save(:validate => false)
      ts.save!
      # TODO - check if break if correct idea, we should rollback previous change(s) in this loop
      if !ts.errors.empty?
        error << ts.errors.full_messages
        break
      end
      pts.teacher_schedule_id = ts.id
    }
    # This is a hack, just to make sure the relevant notifications are sent out
    pts.state = ::ProgramTeacherSchedule::STATE_UNKNOWN
    pts.send(::ProgramTeacherSchedule::EVENT_BLOCK) if error.empty?
    error << pts.errors.full_messages if !pts.errors.empty?
    error
  end

  def load_relevant_teachers
    return [] if @program_teacher_schedule.program.nil?

    program = @program_teacher_schedule.program
    # get all teachers for specific program type
    teacher_ids = ProgramTypesTeachers.find_all_by_program_type_id(program.program_type_id).map { |pts| pts[:teacher_id] }
    program.timings.each {|t|
      # if teacher is available for each of timing specified in the program for the specified center
      teacher_ids &= TeacherSchedule.where(['start_date <= ? AND end_date >= ? AND timing_id = ? AND state = ? AND center_id = ? AND program_type_id IS ?',
                                         program.start_date.to_date, program.end_date.to_date, t.id,
                                         ::TeacherSchedule::STATE_AVAILABLE, program.center_id, program.program_type_id]).pluck(:teacher_id)
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
