class TeacherSchedulesController < ApplicationController
  before_filter :authenticate_user!
  #before_filter :load_teacher!

  # GET /teacher_schedules
  # GET /teacher_schedules.json
  def index
    # expiring the schedules if needed, whenever the results are displayed to the user. This is a backup to the whenever cron job
    # TODO - check in case the user had the session open since a long time.
    TeacherSchedule.mark_as_expired
    @teacher = Teacher.find(params[:teacher_id])
    @teacher.current_user = current_user

    center_scheduler_center_ids = current_user.accessible_center_ids(:center_scheduler)
    zao_zone_ids = current_user.accessible_zone_ids(:zao)
    full_time_teacher_scheduler_zone_ids = current_user.accessible_zone_ids(:full_time_teacher_scheduler)
    full_time_teacher_scheduler_center_ids = current_user.accessible_center_ids(:full_time_teacher_scheduler)

    teacher_schedules = []
    # get the schedules for part-time teachers, from centers for which current_user is center_scheduler (or above)
    unless center_scheduler_center_ids.empty?
      teacher_schedules += @teacher.teacher_schedules.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").joins("JOIN teachers ON teachers.id = teacher_schedules.teacher_id").where("teacher_schedules.end_date >= ? AND centers_teacher_schedules.center_id IN (?) AND teachers.full_time = ?", (Time.zone.now.to_date - 1.month.from_now.to_date), center_scheduler_center_ids, false).group("coalesce(teacher_schedules.program_id, teacher_schedules.id)").order("teacher_schedules.start_date DESC")
    end

    # get the schedules for full-time teachers, from zones for which current_user is zao (or above)
    unless zao_zone_ids.empty?
      teacher_schedules += @teacher.teacher_schedules.joins("JOIN teachers ON teachers.id = teacher_schedules.teacher_id").where("teacher_schedules.end_date >= ? AND teachers.zone_id IN (?) AND teachers.full_time = ?", (Time.zone.now.to_date - 1.month.from_now.to_date), zao_zone_ids, true).group("coalesce(teacher_schedules.program_id, teacher_schedules.id)").order("teacher_schedules.start_date DESC")
    end

    # get the schedules for full-time teachers, from zones for which current_user is full_time_teacher_scheduler (or above)
    unless full_time_teacher_scheduler_zone_ids.empty?
      teacher_schedules += @teacher.teacher_schedules.joins("JOIN teachers ON teachers.id = teacher_schedules.teacher_id").where("teacher_schedules.end_date >= ? AND teachers.zone_id IN (?) AND teachers.full_time = ?", (Time.zone.now.to_date - 1.month.from_now.to_date), full_time_teacher_scheduler_zone_ids, true).group("coalesce(teacher_schedules.program_id, teacher_schedules.id)").order("teacher_schedules.start_date DESC")
    end

    # get the schedules for part-time teachers enabled as co-teachers, from centers for which current_user is full_time_teacher_scheduler (or above)
    unless full_time_teacher_scheduler_center_ids.empty?
      teacher_schedules += @teacher.teacher_schedules.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").joins("JOIN teachers ON teachers.id = teacher_schedules.teacher_id").where("teacher_schedules.end_date >= ? AND centers_teacher_schedules.center_id IN (?) AND teachers.full_time = ? AND teachers.part_time_co_teacher = ?", (Time.zone.now.to_date - 1.month.from_now.to_date), center_scheduler_center_ids, false, true).group("coalesce(teacher_schedules.program_id, teacher_schedules.id)").order("teacher_schedules.start_date DESC")
    end

    @teacher_schedules = teacher_schedules.uniq

    respond_to do |format|
      if @teacher.can_view_schedule?
        format.html
        format.json { render json: @teacher_schedules }
      else
        format.html { redirect_to teacher_path(@teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher.errors, status: :unprocessable_entity }
      end
    end
  end


  # GET /teacher_schedules/new
  # GET /teacher_schedules/new.json
  def new
    @teacher = Teacher.find(params[:teacher_id])
    @teacher_schedule = TeacherSchedule.new
    @teacher_schedule.teacher = @teacher
    @teacher.current_user = @teacher_schedule.current_user = current_user

    load_program_type_timings!(@teacher)
    #@program_types = ProgramType.joins('JOIN program_types_teachers ON program_types.id = program_types_teachers.program_type_id').where('program_types_teachers.teacher_id IS ?', @teacher.id).all.sort_by{|pt| pt[:name]}
    #@selected_program_type = @program_types[0]
    #@timings = @selected_program_type.timings.sort_by{|t| t[:start_time]}

    respond_to do |format|
      if @teacher_schedule.can_create?
        format.html
        format.json { render json: @teacher_schedule }
      else
        format.html { redirect_to teacher_teacher_schedules_path(@teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
      end
    end
  end


  # GET /teacher_schedules/reserve
  # GET /teacher_schedules/reserve.json
  def reserve
    @teacher = Teacher.find(params[:teacher_id].to_i)
    @trigger = params[:trigger]
    @teacher_schedule = TeacherSchedule.new
    @teacher_schedule.teacher = @teacher
    @teacher.current_user = @teacher_schedule.current_user = current_user
    load_reserve_states!

    respond_to do |format|
      if @teacher_schedule.can_create?
        format.html { render action: "reserve" }
        format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
      else
        format.html { redirect_to teacher_teacher_schedules_path(@teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
      end
    end
  end


  # GET /teacher_schedules/1
  # GET /teacher_schedules/1.json
  def show
    @teacher = Teacher.find(params[:teacher_id])
    @teacher_schedule = TeacherSchedule.find(params[:id])
    @teacher.current_user = @teacher_schedule.current_user = @teacher_schedule.teacher.current_user = current_user

    respond_to do |format|
      if @teacher_schedule.can_update?
        format.html # show.html.erb
        format.json { render json: @teacher_schedule }
      else
        format.html { redirect_to teacher_teacher_schedules_path(@teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
      end
    end

  end

  def create_on_trigger

    @teacher = Teacher.find(params[:teacher_id])
    @teacher_schedule = TeacherSchedule.new(params[:teacher_schedule])
    @teacher_schedule.teacher = @teacher
    @teacher_schedule.current_user = @teacher.current_user = current_user
    @trigger = params[:trigger]

    respond_to do |format|
      if @teacher_schedule.can_create?
        if @teacher_schedule.valid? && @teacher_schedule.save
          format.html { redirect_to teacher_teacher_schedule_path(@teacher, @teacher_schedule) }
          format.json { render json: @teacher_schedule, status: :created}
        else
          load_reserve_states!(params[:teacher_schedule][:state])
          format.html { render action: "reserve" }
          format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to teacher_teacher_schedules_path(@teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
      end
    end
  end


  # POST /teacher_schedules
  # POST /teacher_schedules.json
  def create
    # In case it is a reserve, call relevant handler
    if params.has_key?('trigger')
      return create_on_trigger
    end

    @teacher = Teacher.find(params[:teacher_id])
    @teacher_schedule = TeacherSchedule.new(params[:teacher_schedule])
    @teacher_schedule.teacher = @teacher
    @teacher_schedule.current_user = @teacher.current_user = current_user

    respond_to do |format|
      if !@teacher_schedule.can_create?
        format.html { redirect_to teacher_teacher_schedules_path(@teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
      else
        @teacher_schedule.errors[:base] << "At least one Timing should be selected." if params[:teacher_schedule][:timing_id].nil?
        @teacher_schedule.errors[:base] << "At least one Center should be selected." if params[:teacher_schedule][:center_ids].nil?

        if (@teacher_schedule.errors.empty?)
          timing_arr = params[:teacher_schedule][:timing_id]
          timing_arr.each { |timing_id|
            @teacher_schedule = TeacherSchedule.new(params[:teacher_schedule])
            @teacher_schedule.current_user = current_user
            @teacher_schedule.teacher_id = params[:teacher_id]
            #@teacher_schedule.program_type_id = params[:teacher_schedule][:program_type_id]
            @teacher_schedule.timing_id = timing_id
            if @teacher_schedule.valid?
              additional_days = @teacher_schedule.can_combine_consecutive_schedules?
              if (additional_days + @teacher_schedule.no_of_days < 3)
#              if (additional_days + @teacher_schedule.no_of_days < @teacher_schedule.program_type.no_of_days)
                load_program_type_timings!(@teacher)
                @teacher_schedule.errors[:end_date] << "should exceed Start date by at least 2 days."
                format.html { render action: "new" }
                format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
              else
                @teacher_schedule.combine_consecutive_schedules! if additional_days != 0
                if !@teacher_schedule.save
                  load_program_type_timings!(@teacher)
                  format.html { render action: "new" }
                  format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
                else
                  format.html { redirect_to(teacher_teacher_schedule_path(@teacher, @teacher_schedule)) }
                  format.json { render json: @teacher_schedule, status: :created}
                end
              end
            else
              load_program_type_timings!(@teacher)
              format.html { render action: "new" }
              format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
            end
          }
        else
          #@teacher_schedule.errors[:timing] << "At least one timings must be selected."
          load_program_type_timings!(@teacher)
          format.html { render action: "new" }
          format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # GET /teacher_schedules/1/edit
  def edit
    @teacher_schedule = TeacherSchedule.find(params[:id])
    @teacher = @teacher_schedule.teacher
    @teacher.current_user = @teacher_schedule.current_user = @teacher_schedule.teacher.current_user = current_user

    load_program_type_timings_on_update!(@teacher_schedule)
    respond_to do |format|
      if @teacher_schedule.can_update?
        format.html
        format.json { render json: @teacher_schedule }
      else
        format.html { redirect_to teacher_teacher_schedules_path(@teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /teacher_schedules/1
  # PUT /teacher_schedules/1.json
  def update
    @teacher_schedule = TeacherSchedule.find(params[:id])
    @teacher_schedule.assign_attributes(params[:teacher_schedule])
    @teacher = @teacher_schedule.teacher
    @teacher.current_user = @teacher_schedule.current_user = @teacher_schedule.teacher.current_user = current_user

    respond_to do |format|
      if !@teacher_schedule.valid?
        load_program_type_timings_on_update!(@teacher_schedule)
        format.html { render action: "edit" }
        format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
      elsif @teacher_schedule.can_update?
        additional_days = @teacher_schedule.can_combine_consecutive_schedules?
        if (additional_days + @teacher_schedule.no_of_days < 3)
#        if (additional_days + @teacher_schedule.no_of_days < @teacher_schedule.program_type.no_of_days)
          @teacher_schedule.errors[:end_date] << "should exceed Start date by at least 2 days."
          load_program_type_timings_on_update!(@teacher_schedule)
          format.html { render action: "edit" }
          format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
        else
          @teacher_schedule.combine_consecutive_schedules! if additional_days != 0
          if !@teacher_schedule.save
            load_program_type_timings_on_update!(@teacher_schedule)
            format.html { render action: "edit" }
            format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
          else
            format.html { redirect_to teacher_teacher_schedule_path(@teacher, @teacher_schedule), notice: 'Teacher schedule was successfully updated.' }
          end
        end
      else
        format.html { redirect_to teacher_teacher_schedules_path(@teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy_reserve

    @teacher_schedule = TeacherSchedule.find(params[:id])
    @teacher = @teacher_schedule.teacher
    @teacher.current_user = @teacher_schedule.current_user = @teacher_schedule.teacher.current_user = current_user

    # only users making reserve call can delete the corresponding reserved schedules
    respond_to do |format|
      if @teacher_schedule.can_delete?
        @teacher_schedule.delete_reserve!
        format.html { redirect_to teacher_teacher_schedules_path(@teacher) }
        format.json { head :no_content }
      else
        format.html { redirect_to teacher_teacher_schedules_path(@teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
      end
    end

  end

  # DELETE /teacher_schedules/1
  # DELETE /teacher_schedules/1.json
  def destroy
    @teacher_schedule = TeacherSchedule.find(params[:id])
    # re-route in case we are trying to destroy reserve for a full time teacher
    return destroy_reserve if @teacher_schedule.in_reserved_state?
    @teacher = @teacher_schedule.teacher
    @teacher.current_user = @teacher_schedule.current_user = @teacher_schedule.teacher.current_user = current_user

    respond_to do |format|
      if @teacher_schedule.can_delete?
        @teacher_schedule.destroy
          format.html { redirect_to teacher_teacher_schedules_path(@teacher) }
          format.json { head :no_content }
      else
        format.html { redirect_to teacher_teacher_schedules_path(@teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_timings
    # updates timings based on selection
    program_type = ProgramType.find(params[:program_type_id])
    # map to name and id for use in our options_for_select
    @timings = program_type.timings.sort_by{|t| t[:start_time]}.map{|a| [a.name, a.id]}
  end

  def update_centers
    @disable_centers_select = (params[:state] == ::TeacherSchedule::STATE_ACTIVITY) ? false : true
    @selected_reserve_state = params[:state]
  end

  def load_reserve_states!(selected_state = nil)
    @reserve_states = (::TeacherSchedule::RESERVED_STATES).sort
    @selected_reserve_state = selected_state.nil? ? @reserve_states[0] : selected_state
    @disable_centers_select = (@selected_reserve_state == ::TeacherSchedule::STATE_ACTIVITY) ? false : true
  end

  def load_program_type_timings!(teacher)
    #@program_types = ProgramType.joins('JOIN program_types_teachers ON program_types.id = program_types_teachers.program_type_id').where('program_types_teachers.teacher_id = ? OR program_types_teachers.teacher_id IS NULL', teacher.id).all.sort_by{|pt| pt[:name]}
    #@selected_program_type = @program_types[0]
    #@timings = @selected_program_type.timings.sort_by{|t| t[:start_time]}
    @timings = Timings.all.sort_by{|t| t[:start_time]}
  end

  def load_program_type_timings_on_update!(teacher_schedule)
    #@program_types = ProgramType.joins('JOIN program_types_teachers ON program_types.id = program_types_teachers.program_type_id').where('program_types_teachers.teacher_id = ? OR program_types_teachers.teacher_id IS NULL', teacher_schedule.teacher.id).all.sort_by{|pt| pt[:name]}
    #@selected_program_type = teacher_schedule.program_type
    #@timings = @selected_program_type.timings.sort_by{|t| t[:start_time]}
    @timings = Timings.all.sort_by{|t| t[:start_time]}
  end

  private




  #def load_teacher!
  #  @teacher = Teacher.find_by_user_id(current_user.id)
  #end


end
