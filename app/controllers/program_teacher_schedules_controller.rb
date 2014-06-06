class ProgramTeacherSchedulesController < ApplicationController
  before_filter :authenticate_user!
  #before_filter :load_program_teacher_schedule!

  def new
    @program_teacher_schedule = load_program_teacher_schedule!(params)

    if params.has_key?(:teacher_id)
      center_ids = @program_teacher_schedule.teacher.center_ids
    end

    if params.has_key?(:program_id)
      center_ids = [@program_teacher_schedule.program.center_id]
    end

    respond_to do |format|
      if @program_teacher_schedule.can_create?(center_ids)
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
      program = @program_teacher_schedule.program
      teacher = @program_teacher_schedule.teacher
      # Double check if indeed we can block the teacher with the program, because block_teacher_schedule! should not fail
      respond_to do |format|
        if !@program_teacher_schedule.can_create?
          format.html { redirect_to teacher_teacher_schedules_path(@program_teacher_schedule.teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
          format.json { render json: @program_teacher_schedule.errors, status: :unprocessable_entity }
        elsif !teacher.can_be_blocked_by?(program)
          format.html { redirect_to teacher_teacher_schedules_path(@program_teacher_schedule.teacher), :alert => "[ ERROR ] Request timed out, cannot perform the requested action. Please try again." }
          format.json { render json: @program_teacher_schedule.errors, status: :unprocessable_entity }
        else
          @program_teacher_schedule.block_teacher_schedule!(params[:program_teacher_schedule])
          #@program_teacher_schedule = load_program_teacher_schedule!(params[:program_teacher_schedule])
          if @program_teacher_schedule.errors.empty?
            format.html { redirect_to program_teacher_schedule_path(:id => @program_teacher_schedule.teacher_schedule_id), notice: 'Program-Teacher Schedule was successfully updated.'  }
            format.json { render :json => @program_teacher_schedule }

            #format.html { redirect_to program_path(@program_teacher_schedule.program) }
            #format.json { render json: @program_teacher_schedule, status: :created, location: @program_teacher_schedule }
          else
            format.html { render action: "new" }
            format.json { render json: @program_teacher_schedule.errors, status: :unprocessable_entity }
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
    @program_teacher_schedule.comment_category = Comment.where('model = ? AND action = ?', 'ProgramTeacherSchedule', @trigger).pluck(:text)

    unless @program_teacher_schedule.can_update?
      respond_to do |format|
        format.html { redirect_to teacher_teacher_schedules_path(@program_teacher_schedule.teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @program_teacher_schedule.errors, status: :unprocessable_entity }
      end
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
          #flash[:program_teacher_schedule] = @program_teacher_schedule
          #format.html { redirect_to :action => :edit, :trigger => params[:trigger], :id => params[:id]}
          format.html { render :action => :edit, :trigger => params[:trigger], :id => params[:id]}
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
    else
      if params.has_key?(:program_id)
        pts.program_id = (params[:program_id]).to_i
        pts.program = ::Program.find(pts.program_id)
      end
      if params.has_key?(:teacher_id)
        pts.teacher_id = (params[:teacher_id]).to_i
        pts.teacher = Teacher.find(pts.teacher_id)
        pts.teacher.current_user = current_user
      end
    end
    pts
  end


  def state_update(pts, trig)
    pts.current_user = current_user
    if ::ProgramTeacherSchedule::PROCESSABLE_EVENTS.include?(@trigger)
      pts.send(trig)
    end
  end




end
