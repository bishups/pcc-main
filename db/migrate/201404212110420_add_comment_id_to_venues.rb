class AddCommentIdToVenues < ActiveRecord::Migration
  def change
    add_column :venues, :comment_id, :integer
    add_column :venues, :comments, :text
  end
end

