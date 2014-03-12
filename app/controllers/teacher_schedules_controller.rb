class TeacherSchedulesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_teacher!

  def index
    @teacher_schedules = @teacher.teacher_schedules

    respond_to do |format|
      format.html
    end
  end

  def new
    @teacher_schedule = @teacher.teacher_schedules.new

    respond_to do |format|
      format.html
    end
  end

  def show
    @teacher_schedule = @teacher.teacher_schedules.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def create
    @teacher_schedule = @teacher.teacher_schedules.new(params[:teacher_schedule])

    respond_to do |format|
      if @teacher_schedule.save
        format.html { redirect_to(teacher_teacher_schedule_path(@teacher, @teacher_schedule)) }
      else
        format.html { render(:action => 'new') }
      end
    end
  end

  def edit
    @teacher_schedule = @teacher.teacher_schedules.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def update
    @teacher_schedule = @teacher.teacher_schedules.find(params[:id])

    respond_to do |format|
      if @teacher_schedule.update_attributes(params[:teacher_schedule])
        format.html { redirect_to(teacher_teacher_schedule_path(@teacher, @teacher_schedule)) }
      else
        format.html { render(:action => 'edit') }
      end 
    end
  end

  def destroy
    @teacher_schedule = @teacher.teacher_schedules.find(params[:id])
    @teacher_schedule.destroy()

    respond_to do |format|
      format.html { redirect_to teacher_teacher_schedules_path(@teacher) }
    end
  end

private
  
  # TODO: Enforce role
  def load_teacher!
    @teacher = current_user
  end

end
