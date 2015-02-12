class AddCustomSessionDurationToProgramTypes < ActiveRecord::Migration
  def change
    add_column :program_types, :custom_session_duration, :string
  end
end
