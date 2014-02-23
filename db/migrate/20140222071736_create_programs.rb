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
      t.datetime :start_date
      t.datetime :end_date
      t.string :slot
      t.string :announce_program_id
      t.integer :venue_schedule_id
      t.integer :kit_schedule_id

      t.timestamps
    end
  end
end
