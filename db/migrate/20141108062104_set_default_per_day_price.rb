class SetDefaultPerDayPrice < ActiveRecord::Migration
  def up
    change_column :venues, :per_day_price, :integer, :default => 0
    Venue.update_all("per_day_price=0","per_day_price is NULL")
  end

  def down
    change_column :venues, :per_day_price, :integer, :default => nil
  end
end
