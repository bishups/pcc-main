class EditNotificationLogs < ActiveRecord::Migration
  def change
    remove_column :notification_logs, :link
    add_column :notification_logs, :text1, :string
    add_column :notification_logs, :text2, :string
  end
end

