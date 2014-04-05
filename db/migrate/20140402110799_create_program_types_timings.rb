class CreateProgramTypesTimings < ActiveRecord::Migration
  def change
    create_table :program_types_timings do |t|
      t.belongs_to :program_type
      t.belongs_to :timing
    end
  end
end
