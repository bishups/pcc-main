class CreatePincodes < ActiveRecord::Migration
  def change
    create_table :pincodes do |t|
      t.integer :pincode, :limit => 6
      t.string :location_name
      t.references :center

      t.timestamps
    end
    add_index :pincodes, :center_id
  end
end
