class AddPtrIdToTravelRequest < ActiveRecord::Migration
  def change
    add_column :travel_tickets, :pcc_travel_request_id, :integer
  end
end
