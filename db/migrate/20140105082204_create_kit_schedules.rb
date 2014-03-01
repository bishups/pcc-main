class CreateKitSchedules < ActiveRecord::Migration
  def change
    create_table :kit_schedules do |t|
    	t.date :start_date
    	t.date :end_date
    	t.string :state
      t.integer :issued_to_person_id
    	t.integer :blocked_by_person_id
    	t.integer :assigned_to_program_id
      t.timestamps
    end
  end
end
