class EditKitItems < ActiveRecord::Migration
  def change
    remove_column :kit_items, :name, :description, :type, :capacity
    add_column :kit_items, :type, :string
    add_column :kit_items, :description, :string
    add_column :kit_items, :count, :integer
    add_column :kit_items, :comments, :string
    add_column :kit_items, :kit_id, :integer
  end
end

