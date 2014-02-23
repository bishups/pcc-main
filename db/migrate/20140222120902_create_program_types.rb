class CreateProgramTypes < ActiveRecord::Migration
  def change
    create_table :program_types do |t|
      t.string :name
      t.string :language
      t.integer :no_of_days
      t.integer :minimum_no_of_teacher

      t.timestamps
    end
  end
end
