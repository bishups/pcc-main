class AddCommentIdToKits < ActiveRecord::Migration
  def change
    remove_column :kits, :condition_comments, :general_comments
    add_column :kits, :comment_id, :integer
    add_column :kits, :comments, :text
  end
end

