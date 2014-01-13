class CreateVenues < ActiveRecord::Migration
  def change
    create_table :venues do |t|
      t.integer :center_id
      t.integer :zone_id

      t.string :name
      t.text :description
      t.text :address
      t.string :pin_code
      t.string :capacity
      t.integer :seats

      t.string :state

      t.string :contact_name
      t.string :contact_email
      t.string :contact_phone
      t.string :contact_mobile
      t.text :contact_address

      t.boolean :commercial


      t.timestamps
    end
  end
end
