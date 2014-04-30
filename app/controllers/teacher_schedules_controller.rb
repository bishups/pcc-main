class TeacherSchedulesController < ApplicationController
  before_filter :authenticate_user!
  #before_filter :load_teacher!

  # GET /teacher_schedules
  # GET /teacher_schedules.json
  def index
    center_ids = current_user.accessible_center_ids
    @teacher = Teacher.find(params[:teacher_id])
    @teacher.current_user = current_user
    @teacher_schedules = @teacher.teacher_schedules.where("end_date >= ? AND center_id IN (?)", (Time.zone.now.to_date - 1.month.from_now.to_date), center_ids).group("coalesce(program_id, created_at)")

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

  # POST /teacher_schedules
  # POST /teacher_schedules.json
  def create
    @teacher = Teacher.find(params[:teacher_id])
    @teacher_schedule = TeacherSchedule.new(params[:teacher_schedule])
    @teacher_schedule.teacher = @teacher
    @teacher_schedule.current_user = @teacher.current_user = current_user

    respond_to do |format|
      if !@teacher_schedule.can_create?
        format.html { redirect_to teacher_teacher_schedules_path(@teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
      else
        timing_arr = params[:teacher_schedule][:timing_id]
        if (timing_arr)
          timing_arr.each { |timing_id|
            @teacher_schedule = TeacherSchedule.new(params[:teacher_schedule])
            @teacher_schedule.current_user = current_user
            @teacher_schedule.teacher_id = params[:teacher_id]
            @teacher_schedule.timing_id = timing_id
            if @teacher_schedule.valid?
              additional_days = @teacher_schedule.can_combine_consecutive_schedules?
              if (additional_days + @teacher_schedule.no_of_days < 3)
                @teacher_schedule.errors[:end_date] << "cannot be less than 2 days after start date."
                format.html { render action: "new" }
                format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
              else
                @teacher_schedule.combine_consecutive_schedules! if additional_days != 0
                if !@teacher_schedule.save
                  format.html { render action: "new" }
                  format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
                else
                  format.html { redirect_to(teacher_teacher_schedule_path(@teacher, @teacher_schedule)) }
                end
              end
            else
              format.html { render action: "new" }
              format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
            end
          }
        else
          @teacher_schedule.errors[:timing] << "At least one timings must be selected."
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
      if @teacher_schedule.can_update?
        additional_days = @teacher_schedule.can_combine_consecutive_schedules?
        if (additional_days + @teacher_schedule.no_of_days < 3)
          @teacher_schedule.errors[:end_date] << "cannot be less than 2 days after start date."
          format.html { render action: "edit" }
          format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
        else
          @teacher_schedule.combine_consecutive_schedules! if additional_days != 0
          if !@teacher_schedule.save
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

  # DELETE /teacher_schedules/1
  # DELETE /teacher_schedules/1.json
  def destroy
    @teacher_schedule = TeacherSchedule.find(params[:id])
    @teacher = @teacher_schedule.teacher
    @teacher.current_user = @teacher_schedule.current_user = @teacher_schedule.teacher.current_user = current_user

    if @teacher_schedule.can_update?
      @teacher_schedule.destroy()
      respond_to do |format|
        format.html { redirect_to teacher_teacher_schedules_path(@teacher) }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to teacher_teacher_schedules_path(@teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

private




  #def load_teacher!
  #  @teacher = Teacher.find_by_user_id(current_user.id)
  #end


end
