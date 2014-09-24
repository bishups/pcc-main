class AddOtherToPccCommunicationRequest < ActiveRecord::Migration
  def change
    add_column :pcc_communication_requests, :other_target_audience, :string
    add_column :pcc_communication_requests, :other_geography, :string
  end
end
