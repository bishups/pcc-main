class DropUniqConstrainEmailInUsers < ActiveRecord::Migration
  def up
    change_column :users, :email, :string, :unique => false
    remove_index :users, :email
    add_index :users, :email
  end

  def down

  end
end
