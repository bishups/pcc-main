class EditKits < ActiveRecord::Migration
  def change
    remove_column :kits, :filling_person_id
    remove_column :kits, :kit_name_string
    remove_column :kits, :max_participant_number
    add_column :kits, :requester_id, :integer
    add_column :kits, :name, :string
    add_column :kits, :capacity, :integer
  end
end

