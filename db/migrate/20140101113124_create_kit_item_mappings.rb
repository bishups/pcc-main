class CreateKitItemMappings < ActiveRecord::Migration
  def change
    create_table :kit_item_mappings do |t|
  		t.integer :kit_id
  		t.integer :kit_item_id
  		t.integer :count
  		t.string :condition
  		t.text :comments
      t.timestamps
    end
  end
end
