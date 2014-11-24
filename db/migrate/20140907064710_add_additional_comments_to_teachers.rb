class AddAdditionalCommentsToTeachers < ActiveRecord::Migration
  def change
    add_column :teachers, :additional_comments, :text
  end
end
