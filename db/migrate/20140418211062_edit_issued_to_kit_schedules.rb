class EditIssuedToKitSchedules < ActiveRecord::Migration
  def change
    remove_column :kit_schedules, :issued_to_user_id
    add_column :kit_schedules, :issued_to, :string
  end
end

