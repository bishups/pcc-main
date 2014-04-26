class CreateTeachers < ActiveRecord::Migration
  def change
    create_table :teachers do |t|
      t.string :t_no
      t.string :state
      t.boolean :is_attached
      t.belongs_to :zone
      t.belongs_to :user
      t.timestamps
    end
  end
end
