class CreatePccCommunicationRequests < ActiveRecord::Migration
  def change
    create_table :pcc_communication_requests do |t|
      t.integer :requester_id
      t.string :purpose
      t.string :target_audience
      t.string :attachment
      t.string :state
      t.string :last_update
      t.integer :last_updated_by_user_id
      t.datetime :last_updated_at

      t.timestamps
    end
  end
end
