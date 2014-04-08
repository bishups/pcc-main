class EditPrograms < ActiveRecord::Migration
  def change
    remove_column :programs, :manager_id, :slot, :venue_schedule_id, :kit_schedule_id
    add_column :programs, :last_updated_by_user_id, :integer
  end
end

