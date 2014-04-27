class AddDeletedAtToKits < ActiveRecord::Migration
  def change
    add_column :kits, :deleted_at, :datetime
    add_index :kits, :deleted_at
  end
end
