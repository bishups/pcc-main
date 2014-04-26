class AddStateToTeacherSchedules < ActiveRecord::Migration
  def change
    add_column :teacher_schedules, :state, :string
  end
end
