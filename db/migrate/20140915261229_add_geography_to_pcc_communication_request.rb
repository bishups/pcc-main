class AddGeographyToPccCommunicationRequest < ActiveRecord::Migration
  def change
    add_column :pcc_communication_requests, :geography, :string
  end
end
