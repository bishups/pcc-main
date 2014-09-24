class RemoveZoneIdFromTeacher < ActiveRecord::Migration
  def change
    remove_column :teachers, :zone_id
  end
end
