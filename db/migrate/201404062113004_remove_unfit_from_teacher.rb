class RemoveUnfitFromTeacher < ActiveRecord::Migration
  def change
    remove_column :teachers, :unfit
    remove_column :teachers, :is_attached
  end
end

