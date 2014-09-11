class CreateZonesTeachers < ActiveRecord::Migration
  def change
    create_table :zones_teachers do |t|
      t.belongs_to :zone
      t.belongs_to :teacher
    end
  end
end
