class AddKitIdToKitSchedules < ActiveRecord::Migration
  def change
    add_column :kit_schedules , :kit_id, :integer
  end
end
