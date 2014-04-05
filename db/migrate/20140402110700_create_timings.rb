class CreateTimings < ActiveRecord::Migration
  def change
    create_table :timings do |t|
      t.string :name
      t.time :start_time
      t.time :end_time
      t.timestamps
    end
  end
end
