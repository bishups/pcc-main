class EditDueDateKitSchedules < ActiveRecord::Migration
  def change
    add_column :kit_schedules, :due_date_time, :datetime
  end
end

