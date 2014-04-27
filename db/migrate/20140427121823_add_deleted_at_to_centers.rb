class AddDeletedAtToCenters < ActiveRecord::Migration
  def change
    add_column :centers, :deleted_at, :datetime
    add_index :centers, :deleted_at
  end
end
