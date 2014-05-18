class RemoveZoneIdFromVenue < ActiveRecord::Migration
  def change
    remove_column :venues, :zone_id
  end
end
