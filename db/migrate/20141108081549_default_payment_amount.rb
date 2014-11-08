class DefaultPaymentAmount < ActiveRecord::Migration
  def up
    change_column :venue_schedules, :payment_amount, :integer, :default => 0
    VenueSchedule.update_all("payment_amount=0","payment_amount is NULL")
  end

  def down
    change_column :venue_schedules, :payment_amount, :integer, :default => nil
  end
end
