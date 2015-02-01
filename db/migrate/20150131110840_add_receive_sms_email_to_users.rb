class AddReceiveSmsEmailToUsers < ActiveRecord::Migration
  def up
    add_column :users, :receive_email, :boolean, :default => true
    add_column :users, :receive_sms, :boolean, :default => true
  end

  def down
  end
end
