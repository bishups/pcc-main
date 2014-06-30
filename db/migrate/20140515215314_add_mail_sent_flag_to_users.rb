class AddMailSentFlagToUsers < ActiveRecord::Migration
  def change
    add_column :users, :approval_email_sent, :boolean, :default => false
  end
end

