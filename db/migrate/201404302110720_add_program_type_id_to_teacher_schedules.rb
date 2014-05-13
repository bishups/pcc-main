class AddProgramTypeIdToTeacherSchedules < ActiveRecord::Migration
  def change
    add_column :teacher_schedules, :program_type_id, :integer
  end
end

