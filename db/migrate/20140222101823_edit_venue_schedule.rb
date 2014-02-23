class EditVenueSchedule < ActiveRecord::Migration
  def up
    add_column :venue_schedules, :program_id, :integer
    add_column :venue_schedules, :state, :string
  end

  def down
    remove_column :venue_schedules, :program_id
    remove_column :venue_schedules, :state
  end
end
