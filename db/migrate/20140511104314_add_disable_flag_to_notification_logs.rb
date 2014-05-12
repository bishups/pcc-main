class AddDisableFlagToNotificationLogs < ActiveRecord::Migration
  def change
    add_column :notification_logs, :disabled, :boolean, :default => false
  end
end

