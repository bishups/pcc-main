class EditDatesKitSchedules < ActiveRecord::Migration
  def change
    remove_column :kit_schedules, :start_date, :end_date
    add_column :kit_schedules, :start_date, :datetime
    add_column :kit_schedules, :end_date, :datetime
  end
end

