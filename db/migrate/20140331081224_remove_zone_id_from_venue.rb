class RemoveZoneIdFromVenue < ActiveRecord::Migration
  def change
    remove_column :venues, :zone_id, :integer
  end
end
