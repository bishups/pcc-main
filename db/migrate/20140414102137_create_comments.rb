class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.string :model
      t.string :action
      t.string :text

      t.timestamps
    end
  end
end
