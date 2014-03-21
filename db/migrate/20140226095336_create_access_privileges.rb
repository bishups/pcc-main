class CreateAccessPrivileges < ActiveRecord::Migration
  def change
    create_table :access_privileges do |t|
      t.references :role
      t.references :user
      t.integer :resource_id
      t.string :resource_type
      t.timestamps
    end
    add_index :access_privileges, :role_id
    add_index :access_privileges, :user_id
  end
end
