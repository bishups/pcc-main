class AddPidToPrograms < ActiveRecord::Migration
  def change
    remove_column :programs, :announce_program_id
    add_column :programs, :pid, :string
    add_column :programs, :announced, :boolean, :default => false
  end
end

