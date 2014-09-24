class CreatePccTravelRequests < ActiveRecord::Migration
  def up
    create_table :pcc_travel_requests do |t|
      t.string :purpose
      t.date :doj
      t.time :timefrom
      t.time :timeto
      t.string :from
      t.string :to
      t.string :mode
      t.string :preferred_clss
      t.boolean :tatkal
      t.string :idproof
      t.integer :idproofnumber
      t.string :state
      t.string :comment_category
      t.string :comments
      t.integer :requester_id
      t.string :updated_by
      t.string :last_update
      t.integer :last_updated_by_user_id
      t.datetime :last_updated_at
      t.timestamps
    end
  end
  def down
    drop_table :pcc_travel_requests
  end
end
