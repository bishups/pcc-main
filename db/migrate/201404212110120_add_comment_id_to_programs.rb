class AddCommentIdToPrograms < ActiveRecord::Migration
  def change
    add_column :programs, :comment_id, :integer
  end
end

