class CreateEnquiries < ActiveRecord::Migration
  def change
    create_table :enquiries do |t|
      t.string :topic
      t.string :name
      t.string :email
      t.string :phone
      t.string :mobile
      t.text :description
      t.string :state
      t.string :external_id

      t.timestamps
    end
  end
end
