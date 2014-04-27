class DeleteCommentId < ActiveRecord::Migration
  def change
    remove_column :kit_schedules, :comment_id, :end_date
  end
end

