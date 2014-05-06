class EditActivityNotificationLogs < ActiveRecord::Migration
  def change
    remove_column :activity_logs, :log
    remove_column :notification_logs, :log
    add_column :activity_logs, :text, :string
    add_column :notification_logs, :text, :string
    add_column :notification_logs, :link, :string
  end
end

