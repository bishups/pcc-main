class CreateDateTimings < ActiveRecord::Migration
  def change
    create_table :date_timings do |t|
      t.date :date
      t.belongs_to  :timing
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end
  end
end
