class AddDeletedAtToPincodes < ActiveRecord::Migration
  def change
    add_column :pincodes, :deleted_at, :datetime
    add_index :pincodes, :deleted_at
  end
end
