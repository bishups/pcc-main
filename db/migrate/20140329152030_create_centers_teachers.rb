class CreateCentersTeachers < ActiveRecord::Migration
  def change
    create_table :centers_teachers do |t|
      t.belongs_to :center
      t.belongs_to :teacher
    end
  end
end
