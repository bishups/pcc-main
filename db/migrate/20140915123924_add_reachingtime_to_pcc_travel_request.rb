class AddReachingtimeToPccTravelRequest < ActiveRecord::Migration
  def change
    add_column :pcc_travel_requests, :reachbefore, :datetime
  end
end
