class AddDetailsToTeacher < ActiveRecord::Migration
  def change
    add_column :teachers, :isha_teacher_id, :string
  end
end
