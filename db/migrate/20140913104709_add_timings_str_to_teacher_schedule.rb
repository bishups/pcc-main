class AddTimingsStrToTeacherSchedule < ActiveRecord::Migration
  def change
    add_column :teacher_schedules, :timings_str, :string
  end
end
