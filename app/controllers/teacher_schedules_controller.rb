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
#      if @teacher_schedule.save
      if @teacher_schedule.valid?
#        @teacher_schedule = TeacherSchedulesHelper.combine_consecutive_schedules(@teacher_schedule)
        puts "### Amit ###"
#        @teacher_schedule = combine_consecutive_schedules(@teacher_schedule)
        @teacher_schedule1 = combine_consecutive_schedules(@teacher_schedule)
        @teacher_schedule.save
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
        @teacher_schedule = combine_consecutive_schedules(@teacher_schedule)
        @teacher_schedule.save
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

  def combine_consecutive_schedules2(ts)
    teacher_schedule = TeacherSchedule.where(['end_date = ? AND slot = ? AND user_id = ?', ts.start_date - 1.day, ts.slot, ts.user_id]).first

    if (teacher_schedule != nil)
      ts.start_date = teacher_schedule.start_date
    end

    teacher_schedule = TeacherSchedule.where(['start_date = ? AND slot = ? AND user_id = ?', ts.end_date + 1.day, ts.slot, ts.user_id]).first

    if (teacher_schedule != nil)
      ts.end_date = teacher_schedule.end_date
    end

    return ts
  end

  def combine_consecutive_schedules(ts)
    if (ts.state == ::Ontology::Teacher::STATE_AVAILABLE || ts.state == ::Ontology::Teacher::STATE_UNAVAILABLE)
      teacher_schedule = TeacherSchedule.where(['end_date = ? AND slot = ? AND state = ? AND user_id = ?', ts.start_date - 1.day, ts.slot, ts.state, ts.user_id]).first

      if (teacher_schedule != nil)
        ts.start_date = teacher_schedule.start_date
        teacher_schedule.delete
      end

      teacher_schedule = TeacherSchedule.where(['start_date = ? AND slot = ? AND state = ? AND user_id = ?', ts.end_date + 1.day, ts.slot, ts.state, ts.user_id]).first

      if (teacher_schedule != nil)
        ts.end_date = teacher_schedule.end_date
        teacher_schedule.delete
      end
    end
    return ts
  end

end
