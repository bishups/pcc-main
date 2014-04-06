class AddCenterIdToTeacherSchedules < ActiveRecord::Migration
  def change
    add_column :teacher_schedules, :center_id, :integer
  end
end

