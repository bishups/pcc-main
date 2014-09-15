class CreateZonesTeachers < ActiveRecord::Migration
  def up
    create_table :zones_teachers do |t|
      t.belongs_to :zone
      t.belongs_to :teacher
    end
    Teacher.all.each do |teacher|
      puts "#{teacher.id} zone id is #{teacher.zone_id}"
      teacher.zone_ids= [teacher.zone_id] 	
    end	
  end
  
 def down
 end

end
