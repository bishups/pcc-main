class CreateProgramDonations < ActiveRecord::Migration
  def change
    create_table :program_donations do |t|
      t.references :program_type
      t.integer :donation
      t.string :name
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :program_donations, :program_type_id
    add_index :program_donations, :deleted_at
  end
end
