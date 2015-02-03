class DeleteCommentId < ActiveRecord::Migration
  def change
    remove_column :kit_schedules, :comment_id
    remove_column :kits, :comment_id, :requester_id
    remove_column :programs, :comment_id
    remove_column :teacher_schedules, :comment_id, :teacher_comments
    remove_column :teachers, :comment_id
    remove_column :venue_schedules, :comment_id
    remove_column :venues, :comment_id, :seats
  end
end

