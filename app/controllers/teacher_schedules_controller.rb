class TeacherSchedulesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_teacher!

  def index
    @teacher_schedules = TeacherSchedule.find_all_by_teacher_id(@teacher.id)

    respond_to do |format|
      format.html
    end
  end

  def new
    @teacher_schedule = TeacherSchedule.new

    respond_to do |format|
      format.html
    end
  end

  def show
    @teacher_schedule = TeacherSchedule.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def create
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
          @teacher_schedule.save
          format.html { redirect_to(teacher_teacher_schedule_path(@teacher, @teacher_schedule)) }
        end
      else
        format.html { render action: "new" }
        format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    #@teacher_schedule = @teacher.teacher_schedules.find(params[:id])
    @teacher_schedules = TeacherSchedule.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def update
    #@teacher_schedule = @teacher.teacher_schedules.find(params[:id])
    @teacher_schedules = TeacherSchedule.find(params[:id])

    respond_to do |format|
      if @teacher_schedule.update_attributes(params[:teacher_schedule])
        additional_days = @teacher_schedule.combine_consecutive_schedules?
        if (additional_days + @teacher_schedule.no_of_days < 3)
          @teacher_schedule.errors[:end_date] << "cannot be less than 2 days after start date."
          format.html { render action: "edit" }
          format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
        else
          @teacher_schedule.combine_consecutive_schedules if additional_days != 0
          @teacher_schedule.save
          format.html { redirect_to(teacher_teacher_schedule_path(@teacher, @teacher_schedule)) }
        end
      else
        format.html { render action: "edit" }
        format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
      end 
    end
  end

  def destroy
    # @teacher_schedule = @teacher.teacher_schedules.find(params[:id])
    @teacher_schedules = TeacherSchedule.find(params[:id])

    @teacher_schedule.destroy()

    respond_to do |format|
      format.html { redirect_to teacher_teacher_schedules_path(@teacher) }
    end
  end

private
  
  # TODO: Enforce role
  def load_teacher!
    @teacher = Teacher.find_by_user_id(current_user.id)
  end


end
