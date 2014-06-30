class AddPasswordResetDate < ActiveRecord::Migration
  def up
    add_column :users, :password_reset_at, :datetime
  end

  def down
    remove_column :users, :password_reset_at
  end
end
