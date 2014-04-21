class AddCommentIdToTeachers < ActiveRecord::Migration
  def change
    add_column :teachers, :comment_id, :integer
  end
end

