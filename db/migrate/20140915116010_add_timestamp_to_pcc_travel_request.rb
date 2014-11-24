class AddTimestampToPccTravelRequest < ActiveRecord::Migration
  def change
    add_column :pcc_travel_requests, :timestamp, :datetime
  end
end
