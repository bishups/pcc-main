class AddPincodeIdToVenues < ActiveRecord::Migration
  def change
    remove_column :venues, :pin_code
    add_column :venues, :pincode_id, :integer
  end
end

