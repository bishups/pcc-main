class EditVenueSchedules < ActiveRecord::Migration
  def change
    remove_column :venue_schedules, :slot, :start_date, :end_date, :reserving_user_id
    add_column :venue_schedules, :blocked_by_user_id, :integer
    add_column :venue_schedules, :last_updated_by_user_id, :integer
  end
end

