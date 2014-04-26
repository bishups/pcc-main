class CreateRolesUsers2 < ActiveRecord::Migration
  def up
    create_table(:roles_users) do |t|
      t.integer :role_id
      t.integer :user_id

      t.timestamps
    end

    add_index :roles_users, :role_id, :unique => true
    add_index :roles_users, :user_id, :unique => true
  end

  def down
    drop_table :roles_users
  end
end
