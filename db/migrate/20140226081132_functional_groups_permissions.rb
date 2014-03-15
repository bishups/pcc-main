class FunctionalGroupsPermissions < ActiveRecord::Migration
  def change
    create_table :functional_groups_permissions, :id => false do |t|
      t.integer :functional_group_id
      t.integer :permission_id
    end
  end
end
