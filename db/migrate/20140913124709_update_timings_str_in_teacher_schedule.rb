class UpdateTimingsStrInTeacherSchedule < ActiveRecord::Migration
  def change
    remove_column :teacher_schedules, :timings_str
    add_column :teacher_schedules, :timing_str, :string
  end
end
