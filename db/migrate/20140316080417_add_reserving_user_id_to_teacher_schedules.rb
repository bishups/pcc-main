class AddReservingUserIdToTeacherSchedules < ActiveRecord::Migration
  def change
    add_column :teacher_schedules, :reserving_user_id, :integer
  end
end
