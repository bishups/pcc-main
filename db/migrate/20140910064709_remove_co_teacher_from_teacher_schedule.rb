class RemoveCoTeacherFromTeacherSchedule < ActiveRecord::Migration
  def change
    remove_column :teacher_schedules, :co_teacher
    add_column :teacher_schedules, :role, :string
  end
end
