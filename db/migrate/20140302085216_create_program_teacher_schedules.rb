class CreateProgramTeacherSchedules < ActiveRecord::Migration
  def change
    create_table :program_teacher_schedules do |t|
      t.integer :program_id
      t.integer :user_id
      t.integer :teacher_schedule_id
      t.integer :created_by_user_id

      # Redundant with Program however required for overlap validation
      t.integer :start_date
      t.integer :end_date
      t.integer :slot

      t.timestamps
    end
  end
end
