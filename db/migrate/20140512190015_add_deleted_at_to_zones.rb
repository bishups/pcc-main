class AddDeletedAtToZones < ActiveRecord::Migration
  def change
    add_column :zones, :deleted_at, :datetime
    add_index :zones, :deleted_at
  end
end
