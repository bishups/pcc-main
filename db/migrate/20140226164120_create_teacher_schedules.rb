class CreateTeacherSchedules < ActiveRecord::Migration
  def change
    create_table :teacher_schedules do |t|
      t.integer :user_id
      
      t.string :slot
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps
    end
  end
end
