class RemoveIntroDayFromProgramTypes < ActiveRecord::Migration
  def change
    remove_column :program_types, :intro_day
  end
end

