class AddCapabilitiesToTeachers < ActiveRecord::Migration
  def change
    add_column :teachers, :capabilities, :text
  end
end
