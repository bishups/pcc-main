class AddIdproofnumberToPccTravelRequest < ActiveRecord::Migration
  def change
    add_column :pcc_travel_requests, :idproofnumber, :string
  end
end
