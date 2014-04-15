class TeacherSchedulesController < ApplicationController
  before_filter :authenticate_user!
  #before_filter :load_teacher!

  # GET /teacher_schedules
  # GET /teacher_schedules.json
  def index
    @teacher = Teacher.find(params[:teacher_id])
    @teacher_schedules = TeacherSchedule.where("teacher_id = ?", @teacher.id).group("coalesce(program_id, created_at)")

    respond_to do |format|
      format.html
    end
  end

  # GET /teacher_schedules/new
  # GET /teacher_schedules/new.json
  def new
    @teacher = Teacher.find(params[:teacher_id])
    @teacher_schedule = TeacherSchedule.new

    respond_to do |format|
      format.html
    end
  end

  # GET /teacher_schedules/1
  # GET /teacher_schedules/1.json
  def show
    @teacher = Teacher.find(params[:teacher_id])
    @teacher_schedule = TeacherSchedule.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  # POST /teacher_schedules
  # POST /teacher_schedules.json
  def create
    @teacher = Teacher.find(params[:teacher_id])
    @teacher_schedule = TeacherSchedule.new(params[:teacher_schedule])
    @teacher_schedule.teacher_id = params[:teacher_id]

    respond_to do |format|
      if @teacher_schedule.valid?
        additional_days = @teacher_schedule.combine_consecutive_schedules?
        if (additional_days + @teacher_schedule.no_of_days < 3)
          @teacher_schedule.errors[:end_date] << "cannot be less than 2 days after start date."
          format.html { render action: "new" }
          format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
        else
          @teacher_schedule.combine_consecutive_schedules if additional_days != 0
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
    end
  end

  # GET /teacher_schedules/1/edit
  def edit
    @teacher_schedule = TeacherSchedule.find(params[:id])
    @teacher = @teacher_schedule.teacher
    respond_to do |format|
      format.html
    end
  end

  # PUT /teacher_schedules/1
  # PUT /teacher_schedules/1.json
  def update
    @teacher_schedule = TeacherSchedule.find(params[:id])
    @teacher_schedule.assign_attributes(params[:teacher_schedule])

    respond_to do |format|
      additional_days = @teacher_schedule.combine_consecutive_schedules?
      if (additional_days + @teacher_schedule.no_of_days < 3)
        @teacher_schedule.errors[:end_date] << "cannot be less than 2 days after start date."
        format.html { render action: "edit" }
        format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
      else
        @teacher_schedule.combine_consecutive_schedules if additional_days != 0
        if !@teacher_schedule.save
          format.html { render action: "edit" }
          format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
        else
          format.html { redirect_to(teacher_teacher_schedule_path(@teacher, @teacher_schedule)) }
        end
      end
    end
  end

  # DELETE /teacher_schedules/1
  # DELETE /teacher_schedules/1.json
  def destroy
    @teacher_schedule = TeacherSchedule.find(params[:id])
    @teacher = @teacher_schedule.teacher
    @teacher_schedule.destroy()

    respond_to do |format|
      format.html { redirect_to teacher_teacher_schedules_path(@teacher) }
    end
  end

private
  
  # TODO: Enforce role
  #def load_teacher!
  #  @teacher = Teacher.find_by_user_id(current_user.id)
  #end


end
