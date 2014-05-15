class AddSyncId < ActiveRecord::Migration
  def change
    add_column :users, :sync_id, :integer
    add_column :access_privileges, :sync_id, :integer
    add_column :roles, :sync_id, :integer
    add_column :permissions, :sync_id, :integer
    add_column :teachers, :sync_id, :integer
    add_column :pincodes, :sync_id, :integer
    add_column :centers, :sync_id, :integer
    add_column :sectors, :sync_id, :integer
    add_column :zones, :sync_id, :integer
    add_column :program_types, :sync_id, :integer
    add_column :timings, :sync_id, :integer
    add_column :program_donations, :sync_id, :integer
    add_column :programs, :sync_id, :integer
  end
end

