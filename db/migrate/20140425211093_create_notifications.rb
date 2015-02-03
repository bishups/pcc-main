class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :model
      t.string :from_state
      t.string :to_state
      t.string :on_event
      t.integer :role_id
      t.boolean :send_sms
      t.boolean :send_email
      t.text :additional_text
      t.timestamps
    end
  end
end