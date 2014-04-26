class AddTeacherIdToTeacherSchedules < ActiveRecord::Migration
  def change
    add_column :teacher_schedules, :teacher_id, :integer
  end
end

