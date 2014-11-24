class RemoveCoTeacherFromTeacherSchedule < ActiveRecord::Migration
  def change
    add_column :teacher_schedules, :role, :string
    TeacherSchedule.update_all("role = '#{TeacherSchedule::ROLE_MAIN_TEACHER}'","role is null")    
    TeacherSchedule.update_all("role = '#{TeacherSchedule::ROLE_CO_TEACHER}'","co_teacher=1")
    remove_column :teacher_schedules, :co_teacher
  end
end
