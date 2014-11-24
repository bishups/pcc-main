class CreatePccBreakRequests < ActiveRecord::Migration
  def change
    create_table :pcc_break_requests do |t|
      t.string :purpose
      t.integer :days
      t.date :from
      t.date :to
      t.integer :requester_id
      t.string :state
      t.string :comment_category
      t.string :comments
      t.integer :last_updated_by_user_id
      t.datetime :last_updated_at
      t.string :last_update

      t.timestamps
    end
  end
end
