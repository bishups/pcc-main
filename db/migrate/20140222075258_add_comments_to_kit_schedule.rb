class AddCommentsToKitSchedule < ActiveRecord::Migration
  def change
    add_column :kit_schedules , :comments , :string
  end
end
