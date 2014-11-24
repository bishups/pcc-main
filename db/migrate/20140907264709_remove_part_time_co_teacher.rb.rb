class RemovePartTimeCoTeacher < ActiveRecord::Migration
  def change
    remove_column :teachers, :part_time_co_teacher
  end
end
