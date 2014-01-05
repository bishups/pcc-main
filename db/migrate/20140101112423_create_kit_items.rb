class CreateKitItems < ActiveRecord::Migration
  def change
    create_table :kit_items do |t|
    	t.string :name
    	t.text :description
    	t.text :type
    	t.string :capacity
      t.timestamps
    end
  end
end
