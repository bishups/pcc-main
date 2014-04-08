class AddLastUpdatedToTeacherSchedules < ActiveRecord::Migration
  def change
    remove_column :teacher_schedules, :reserving_user_id
    add_column :teacher_schedules, :blocked_by_user_id, :integer
    add_column :teacher_schedules, :last_updated_by_user_id, :integer
  end
end

