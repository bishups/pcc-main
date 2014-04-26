class AddCommentsToPrograms < ActiveRecord::Migration
  def change
    add_column :programs, :comments, :text
  end
end

