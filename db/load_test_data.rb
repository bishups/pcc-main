3.times do |index|
  Zone.create(:name=>"Zone--#{index}")
end

9.times do |index|
  Sector.create(:name=>"Sector--#{index}", :zone=>Zone.find((index/3)+1))
end

27.times do |index|
  Center.create(:name=>"Center--#{index}", :sector=>Sector.find((index/3)+1))
end

seed_data = YAML::load_file(File.join(Rails.root, 'db/seed-data', 'seed-data.yml'))
kit_items = seed_data["KitItemType"].collect do |kit_item_type|
  kt=KitItemType.where(:name=>kit_item_type).first
  KitItem.new(:description=>" Newly Purchased #{kit_item_type}", :condition=>"Good",:count=>3,:kit_item_type=>kt)
end

seed_data = YAML::load_file(File.join(Rails.root, 'db/seed-data', 'seed-data.yml'))
4.times do |index|
  kit=Kit.new(:condition=>"Good",:name=>"#{Sector.first.centers.first.name} - Kit",:capacity=>50,:centers=>Sector.first.centers+Sector.last.centers)
  kit.save
  seed_data["KitItemType"].collect do |kit_item_type|
    kit_item_type=KitItemType.where(:name=>kit_item_type).first
    kit_item = KitItem.new(:kit=>kit,:description=>" Newly Purchased #{kit_item_type}", :condition=>"Good",:count=>3,:kit_item_type=>kit_item_type)
    if not kit_item.save
      puts " Kit Item not saved due to  #{kit_item.errors.messages}"
    end
  end
end
4.times do |index|
  kit=Kit.new(:condition=>"Good",:name=>"#{Sector.find(2).centers.limit(2).first.name} - Kit",:capacity=>50,:centers=>Sector.find(2).centers.limit(2)+Sector.last.centers.limit(2))
  kit.save
  seed_data["KitItemType"].collect do |kit_item_type|
    kit_item_type=KitItemType.where(:name=>kit_item_type).first
    kit_item = KitItem.new(:kit=>kit,:description=>" Newly Purchased #{kit_item_type}", :condition=>"Good",:count=>3,:kit_item_type=>kit_item_type)
    if not kit_item.save
      puts " Kit Item not saved due to  #{kit_item.errors.messages}"
    end
  end
end
4.times do |index|
  kit=Kit.new(:condition=>"Good",:name=>"#{Sector.first.centers.limit(1).first.name} - Kit",:capacity=>50,:centers=>Sector.first.centers.limit(1)+Sector.last.centers.limit(1))
  kit.save
  seed_data["KitItemType"].collect do |kit_item_type|
    kit_item_type=KitItemType.where(:name=>kit_item_type).first
    kit_item = KitItem.new(:kit=>kit,:description=>" Newly Purchased #{kit_item_type}", :condition=>"Good",:count=>3,:kit_item_type=>kit_item_type)
    if not kit_item.save
      puts " Kit Item not saved due to  #{kit_item.errors.messages}"
    end
  end
end

3.times do |index|
  kit=Kit.new(:condition=>"Good",:name=>"#{Sector.find(index+1).centers.first.name} - Kit",:capacity=>50,:centers=>Sector.find(index+1).centers)
  kit.save
  seed_data["KitItemType"].collect do |kit_item_type|
    kit_item_type=KitItemType.where(:name=>kit_item_type).first
    kit_item = KitItem.new(:kit=>kit,:description=>" Newly Purchased #{kit_item_type}", :condition=>"Good",:count=>3,:kit_item_type=>kit_item_type)
    if not kit_item.save
      puts " Kit Item not saved due to  #{kit_item.errors.messages}"
    end
  end
end

7.times do |index|
  kit=Kit.new(:condition=>"Good",:name=>"#{Center.find(index+1).name} - Kit",:capacity=>50,:centers=>[Center.find(index+1)])
  kit.save
  seed_data["KitItemType"].collect do |kit_item_type|
    kit_item_type=KitItemType.where(:name=>kit_item_type).first
    kit_item = KitItem.new(:kit=>kit,:description=>" Newly Purchased #{kit_item_type}", :condition=>"Good",:count=>3,:kit_item_type=>kit_item_type)
    if not kit_item.save
      puts " Kit Item not saved due to  #{kit_item.errors.messages}"
    end
  end
end

4.times do |index|
  v = Venue.new(:name=>"#{Sector.last.centers.last.name} Venue", :commercial => true ,:capacity=>100,:contact_mobile=>9998908900,:pin_code => 560031, :per_day_price => 100, :address => " Venue Address", :centers => Sector.find(2).centers+Sector.last.centers )
  if not v.save
    puts " Venue not saved due to  #{v.errors.messages}"
  end
end

4.times do |index|
  v=Venue.new(:name=>"#{Sector.first.centers.last.name} Venue", :commercial => true ,:capacity=>100,:contact_mobile=>9998908900,:pin_code => 560031, :per_day_price => 100, :address => "Venue Address", :centers => Sector.first.centers.limit(2)+Sector.last.center )
  if not v.save
    puts " Venue not saved due to  #{v.errors.messages}"
  end
end

4.times do |index|
  v=Venue.new(:name=>"#{Sector.first.centers.first.name} Venue", :commercial => true ,:capacity=>100,:contact_mobile=>9998908900,:pin_code => 560031, :per_day_price => 100, :address => "Venue Address", :centers => Sector.first.centers.limit(1)+Sector.last.center.limit(1) )
  if not v.save
    puts " Venue not saved due to  #{v.errors.messages}"
  end
end

3.times do |index|
  v=Venue.new(:name=>"#{Sector.find(index+1).centers.first.name} Venue", :commercial => true ,:capacity=>100,:contact_mobile=>9998908900,:pin_code => 560031, :per_day_price => 100, :address => "Venue Address", :centers => Sector.find(index+1).centers)
  if not v.save
    puts "Venue not saved due to  #{v.errors.messages}"
  end
end

7.times do |index|
  v=Venue.new(:name=>"#{Center.find(index+1).name} Venue", :commercial => true ,:capacity=>100,:contact_mobile=>9998908900,:pin_code => 560031, :per_day_price => 100, :address => "Venue Address", :centers => [Center.find(index+1)])
  if not v.save
    puts " Venuenot saved due to  #{v.errors.messages}"
  end
end