class ChangeColumnKitItem < ActiveRecord::Migration
  def up
    change_table :kit_items do |t|
      t.rename :type, :kit_item_type
    end
  end

  def down
    change_table :kit_items do |t|
      t.rename :kit_item_type, :type
    end
  end
end
