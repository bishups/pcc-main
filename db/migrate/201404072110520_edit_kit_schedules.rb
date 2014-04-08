class EditKitSchedules < ActiveRecord::Migration
  def change
    remove_column :kit_schedules, :issued_to_person_id, :blocked_by_person_id
    add_column :kit_schedules, :issued_to_user_id, :integer
    add_column :kit_schedules, :blocked_by_user_id, :integer
    add_column :kit_schedules, :last_updated_by_user_id, :integer
  end
end

