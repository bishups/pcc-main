class EditTeacherSchedules < ActiveRecord::Migration
  def change
    remove_column :teacher_schedules, :user_id, :slot, :start_date, :end_date
    add_column :teacher_schedules, :start_date, :date
    add_column :teacher_schedules, :end_date, :date
    add_column :teacher_schedules, :timing_id, :integer
    add_column :teacher_schedules, :program_id, :integer
  end
end

