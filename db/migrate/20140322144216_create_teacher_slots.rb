class CreateTeacherSlots < ActiveRecord::Migration
  def change
    create_table :teacher_slots do |t|
      t.integer :user_id
      t.string :status
      t.string :slot
      t.date :date

      t.timestamps
    end
  end
end
