class TeacherSlotsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_teacher!

  def index

    @teacher_slots_av = @teacher.teacher_slots.where("user_id = ? AND status = ?", @teacher.id, ::TeacherSchedule::STATE_AVAILABLE)
    @teacher_slots_unav = @teacher.teacher_slots.where("user_id = ? AND status = ?", @teacher.id, ::TeacherSchedule::STATE_UNAVAILABLE)
    @teacher_slots_bl = @teacher.teacher_slots.where("user_id = ? AND status = ?", @teacher.id, ::ProgramTeacherSchedule::STATE_BLOCKED)
    @teacher_slots_as = @teacher.teacher_slots.where("user_id = ? AND status = ?", @teacher.id, ::ProgramTeacherSchedule::STATE_ASSIGNED)

    respond_to do |format|
      format.html
    end
  end

  def new
    @teacher_slot = @teacher.teacher_slots.new

    respond_to do |format|
      format.html
    end
  end

  def show
    @teacher_slot = @teacher.teacher_slots.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def create
    @date = Date::strptime(params[:start_date],"%Y-%m-%d")
    @end_date = Date::strptime(params[:end_date],"%Y-%m-%d")
    @slot = params[:slot]
    @status = params[:status]
    @date_arr = (@date..@end_date).to_a
    for date_item in @date_arr
      for slot_item in @slot
        teacher_slot = TeacherSlot.new
        teacher_slot.date = date_item
        teacher_slot.slot = slot_item
        teacher_slot.status = @status
        teacher_slot.user_id = params[:teacher_id]
        teacher_slot.save
      end
    end
    respond_to do |format|
      format.html { redirect_to(teacher_teacher_slots_path(@teacher)) }
    end
#    render text: params[:slot]
#    render text: @date_arr.to_s
  end

private
  
  # TODO: Enforce role
  def load_teacher!
    @teacher = current_user
  end
end
