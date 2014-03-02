class CreateProgramTeacherSchedules < ActiveRecord::Migration
  def change
    create_table :program_teacher_schedules do |t|
      t.integer :program_id
      t.integer :user_id
      t.integer :teacher_schedule_id

      

      t.timestamps
    end
  end
end
