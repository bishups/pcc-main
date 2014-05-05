class AddReadFlagToNotificationLogs < ActiveRecord::Migration
  def change
    add_column :notification_logs, :displayed, :boolean, :default => false
  end
end

