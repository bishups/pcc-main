class CreateSecondaryZonesTeachers < ActiveRecord::Migration
  def up
    create_table :secondary_zones_teachers do |t|
      t.belongs_to :zone
      t.belongs_to :teacher
    end
  end
  
  def down
  end

end
