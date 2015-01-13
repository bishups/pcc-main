class AddIntroInitiationDayToProgramTypes < ActiveRecord::Migration
  def change
    add_column :program_types, :intro_day, :integer
    add_column :program_types, :initiation_day, :integer
    add_column :program_types, :intro_duration, :integer
  end
end

