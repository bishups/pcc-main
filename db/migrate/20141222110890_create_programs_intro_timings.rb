class CreateProgramsIntroTimings < ActiveRecord::Migration
  def change
    create_table :programs_intro_timings do |t|
      t.belongs_to :program
      t.belongs_to :timing
    end
  end
end
