class CreateKits < ActiveRecord::Migration
  def change
    create_table :kits do |t|
    	t.string :state
    	t.integer :max_participant_number
    	t.integer :filling_person_id
    	t.integer :center_id
    	t.integer :guardian_id
    	t.string :condition
    	t.text :condition_comments
    	t.text :general_comments
      t.timestamps
    end
  end
end
