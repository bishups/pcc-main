class AddDeletedAtToProgramTypes < ActiveRecord::Migration

  def change
    add_column :program_types, :deleted_at, :datetime
    add_index :program_types, :deleted_at
  end
end
