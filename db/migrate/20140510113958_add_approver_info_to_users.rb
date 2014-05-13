class AddApproverInfoToUsers < ActiveRecord::Migration
  def up
    add_column :users, :approver_email, :string
    add_column :users, :message_to_approver, :text
  end

  def down
  end
end
