class AddTeacherCommentsToPrograms < ActiveRecord::Migration
  def change
    add_column :programs, :feedback, :text
  end
end

