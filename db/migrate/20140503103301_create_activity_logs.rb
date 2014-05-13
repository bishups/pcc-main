class CreateActivityLogs < ActiveRecord::Migration
  def change
    create_table :activity_logs do |t|
      t.references :user
      t.datetime :date
      t.references :model, :polymorphic => true
      t.string :log

      t.timestamps
    end
    add_index :activity_logs, :user_id
    add_index :activity_logs, :model_id
  end
end
