class CreateChangeSuggestions < ActiveRecord::Migration
  def change
    create_table :change_suggestions do |t|
      t.string :description
      t.string :priority
      t.boolean :done
      t.integer :pcc_communication_request_id

      t.timestamps
    end
  end
end
