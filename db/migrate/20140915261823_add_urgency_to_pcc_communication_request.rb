class AddUrgencyToPccCommunicationRequest < ActiveRecord::Migration
  def change
    add_column :pcc_communication_requests, :urgency, :string
  end
end
