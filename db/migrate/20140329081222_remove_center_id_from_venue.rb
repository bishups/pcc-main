class RemoveCenterIdFromVenue < ActiveRecord::Migration
  def change
    remove_column :venues, :center_id, :integer
  end
end
