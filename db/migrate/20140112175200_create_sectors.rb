class CreateSectors < ActiveRecord::Migration
  def change
    create_table :sectors do |t|
      t.string :name
      t.references :zone

      t.timestamps
    end
    add_index :sectors, :zone_id
  end
end
