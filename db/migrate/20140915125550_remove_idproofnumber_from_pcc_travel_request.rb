class RemoveIdproofnumberFromPccTravelRequest < ActiveRecord::Migration
  def up
    remove_column :pcc_travel_requests, :idproofnumber
  end

  def down
    add_column :pcc_travel_requests, :idproofnumber, :string
  end
end
