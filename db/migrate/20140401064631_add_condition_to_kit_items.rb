class AddConditionToKitItems < ActiveRecord::Migration
  def change
      remove_column :kit_items, :kit_item_type, :type
      add_column :kit_items, :kit_item_name_id, :integer
      add_column :kit_items, :condition, :string
    end
end
