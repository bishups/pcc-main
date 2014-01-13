class CreateCenters < ActiveRecord::Migration
  def change
    create_table :centers do |t|
      t.string :name
      t.references :sector

      t.timestamps
    end
    add_index :centers, :sector_id
  end
end
