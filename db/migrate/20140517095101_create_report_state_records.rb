class CreateReportStateRecords < ActiveRecord::Migration
  def change
    create_table :report_state_records do |t|
      t.string  :record_name
      t.integer :record_id
      t.string  :state
      t.timestamps
    end
  end
end
