class AddActiveToComments < ActiveRecord::Migration
  def change
    add_column :comments, :active, :boolean, :default => 1
  end
end

