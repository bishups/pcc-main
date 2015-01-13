class CreateProgramsDateTimings < ActiveRecord::Migration
  def change
    create_table :programs_date_timings do |t|
      t.belongs_to  :program
      t.belongs_to  :date_timing
    end
  end
end
