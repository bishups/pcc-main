class AddUnfitCommentsToTeacher < ActiveRecord::Migration
  def change
    add_column :teachers, :unfit, :boolean
    add_column :teachers, :comments, :text
  end
end

