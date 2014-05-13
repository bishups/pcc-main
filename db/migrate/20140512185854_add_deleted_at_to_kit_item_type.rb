class AddDeletedAtToKitItemType < ActiveRecord::Migration
  def change
    add_column :kit_item_types, :deleted_at, :datetime
    add_index :kit_item_types, :deleted_at
  end
end
