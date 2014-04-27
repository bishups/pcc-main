class AddDeletedAtToTimings < ActiveRecord::Migration
  def change
    add_column :timings, :deleted_at, :datetime
    add_index :timings, :deleted_at
  end
end
