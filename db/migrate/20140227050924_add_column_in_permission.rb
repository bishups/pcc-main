class AddColumnInPermission < ActiveRecord::Migration
  def up
    add_column :permissions, :cancan_action, :string
    add_column :permissions, :subject, :string
  end

  def down
    remove_column :permissions, :cancan_action, :string
    remove_column :permissions, :subject, :string
  end
end
