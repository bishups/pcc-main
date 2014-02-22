class CreatePrograms < ActiveRecord::Migration
  def change
    create_table :programs do |t|
      t.string :name
      t.text :description
      t.string :center_id
      t.integer :program_type_id
      t.integer :proposer_id
      t.integer :manager_id
      t.string :state
      t.datetime :start_time
      t.datetime :end_time
      t.string :slot
      t.string :announce_program_id

      t.timestamps
    end
  end
end
