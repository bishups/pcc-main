class EditActivityLogs < ActiveRecord::Migration
  def change
    remove_column :activity_logs, :link
    add_column :activity_logs, :text1, :string
    add_column :activity_logs, :text2, :string
  end
end

