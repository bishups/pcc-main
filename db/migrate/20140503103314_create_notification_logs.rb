class CreateNotificationLogs < ActiveRecord::Migration
  def change
    create_table :notification_logs do |t|
      t.references :user
      t.datetime :date
      t.references :model, :polymorphic => true
      t.string :log

      t.timestamps
    end
    add_index :notification_logs, :user_id
    add_index :notification_logs, :model_id
  end
end
