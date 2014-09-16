class AddDeadlineToPccCommunicationRequest < ActiveRecord::Migration
  def change
    add_column :pcc_communication_requests, :deadline, :date
  end
end
