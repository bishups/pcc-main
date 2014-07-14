class AddSyncDetails < ActiveRecord::Migration
    def change
      add_column :zones, :sync_ts, :string
      remove_column :zones, :sync_id
      add_column :zones, :sync_id, :string

      add_column :sectors, :sync_ts, :string
      remove_column :sectors, :sync_id
      add_column :sectors, :sync_id, :string

      add_column :centers, :sync_ts, :string
      remove_column :centers, :sync_id
      add_column :centers, :sync_id, :string

      add_column :users, :sync_ts, :string
      remove_column :users, :sync_id
      add_column :users, :sync_id, :string

      add_column :roles_users, :sync_ts, :string
      #remove_column :roles_users, :sync_id
      add_column :roles_users, :sync_id, :string

      add_column :access_privileges, :sync_ts, :string
      remove_column :access_privileges, :sync_id
      add_column :access_privileges, :sync_id, :string

      add_column :programs, :sync_ts, :string
      remove_column :programs, :sync_id
      add_column :programs, :sync_id, :string

      add_column :program_types, :sync_ts, :string
      remove_column :program_types, :sync_id
      add_column :program_types, :sync_id, :string

      add_column :program_donations, :sync_ts, :string
      remove_column :program_donations, :sync_id
      add_column :program_donations, :sync_id, :string
    end
end
