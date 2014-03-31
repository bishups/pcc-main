class DropRolesUsersKitItemMappings < ActiveRecord::Migration
  def change
    drop_table :roles_users
    drop_table :kit_item_mappings
  end
end
