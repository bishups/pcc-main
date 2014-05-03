class CreateCentersTeacherSchedules < ActiveRecord::Migration
  def change
    create_table :centers_teacher_schedules do |t|
      t.belongs_to :center
      t.belongs_to :teacher_schedule
    end
  end
end
