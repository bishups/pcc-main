class ProgramTeacherSchedulesController < ApplicationController
  before_filter :authenticate_user!

  def new
    @program_teacher_schedule = ProgramTeacherSchedule.new
    @program_teacher_schedule.program = ::Program.find(params[:program_id]) if params[:program_id]
    @teacher_schedules = load_relevant_teacher_schedules()
    
    respond_to do |format|
      format.html do
        if request.xhr?
          render :layout => false
        end 
      end
    end
  end

  def create
    @program_teacher_schedule = ProgramTeacherSchedule.new(params[:program_teacher_schedule])
    @program_teacher_schedule.created_by_user_id = current_user.id
    @teacher_schedules = load_relevant_teacher_schedules()  # required for failed case rendering

    respond_to do |format|
      if @program_teacher_schedule.save
        format.html { redirect_to program_teacher_schedule_path(@program_teacher_schedule) }
      else
        format.html { render(:action => 'new') }
      end
    end
  end


  private

  def load_relevant_teacher_schedules
    return [] if @program_teacher_schedule.program.nil?

    program = @program_teacher_schedule.program
    teacher_s = TeacherSchedule.where(['start_date <= ? AND end_date >= ? AND slot = ?', 
      program.start_date, program.end_date, program.slot]).includes(:user)

    teacher_s.map {|e| e }
  end
end
