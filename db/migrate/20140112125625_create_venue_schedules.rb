class CreateVenueSchedules < ActiveRecord::Migration
  def change
    create_table :venue_schedules do |t|
      t.integer :venue_id
      t.integer :reserving_user_id
      
      t.string :slot
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps
    end
  end
end
