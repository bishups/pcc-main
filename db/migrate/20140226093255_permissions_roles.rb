class PermissionsRoles < ActiveRecord::Migration
  def change
    create_table :permissions_roles, :id => false do |t|
      t.integer :role_id
      t.integer :permission_id
    end
  end
end
