class AddDeletedAtToSectors < ActiveRecord::Migration
  def change
    add_column :sectors, :deleted_at, :datetime
    add_index :sectors, :deleted_at
  end
end
