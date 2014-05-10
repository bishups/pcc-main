class AddEnableUserColumn < ActiveRecord::Migration
  def up
    add_column :users, :enable, :boolean, :default => false
  end

  def down
  end
end
