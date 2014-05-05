class RenameKitItemName < ActiveRecord::Migration
  def up
     rename_table :kit_item_names, :kit_item_types
     rename_column(:kit_items, :kit_item_name_id, :kit_item_type_id)
  end

  def down
     rename_table :kit_item_types, :kit_item_names
     rename_column(:kit_items, :kit_item_type_id, :kit_item_name_id)
  end
end
