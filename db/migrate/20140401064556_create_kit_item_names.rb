class CreateKitItemNames < ActiveRecord::Migration
  def change
    create_table :kit_item_names do |t|
      t.string :name
      t.string :description
      t.timestamps
    end
  end
end
