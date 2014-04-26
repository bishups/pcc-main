class AddCommentIdToKitSchedules < ActiveRecord::Migration
  def change
    remove_column :kit_schedules, :comments
    add_column :kit_schedules, :comment_id, :integer
    add_column :kit_schedules, :comments, :text
    add_column :kit_schedules, :feedback, :text
  end
end

