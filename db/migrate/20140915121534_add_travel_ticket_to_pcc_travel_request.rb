class AddTravelTicketToPccTravelRequest < ActiveRecord::Migration
  def change
    add_column :pcc_travel_requests, :travel_ticket_id, :integer
  end
end
