class AddPerDayPriceToVenueSchedules < ActiveRecord::Migration
  def change
    add_column :venue_schedules, :per_day_price, :integer
  end
end

