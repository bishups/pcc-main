class CreateCentersVenues < ActiveRecord::Migration
  def change
    create_table :centers_venues do |t|
      t.belongs_to :center
      t.belongs_to :venue
    end
  end
end
