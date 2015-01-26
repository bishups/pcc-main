class AddFullDayToProgramTypes < ActiveRecord::Migration
  def change
    add_column :program_types, :full_day, :string
    add_column :program_types, :combined_day, :string
    remove_column :program_types, :initiation_day
  end
end

