class RemoveTextFromLogs < ActiveRecord::Migration
  def change
    remove_column :activity_logs, :text
    remove_column :notification_logs, :text
  end
end
