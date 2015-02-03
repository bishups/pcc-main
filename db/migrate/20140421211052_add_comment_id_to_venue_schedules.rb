class AddCommentIdToVenueSchedules < ActiveRecord::Migration
  def change
    add_column :venue_schedules, :comment_id, :integer
    add_column :venue_schedules, :comments, :text
    add_column :venue_schedules, :feedback, :text
  end
end

