3.times do |index|
  zone=Zone.create(:name=>"Zone--#{index}")
  ["zonal_coordinator","zao","pcc_accounts","finance_department", "teacher_training_department"].each do |role_name|
    user = User.new(:firstname => "#{role_name}-#{index}",:email=> "#{role_name}-#{index}@pcc-ishayoga.org",:mobile=>"9999999999",
                    :password => "#{role_name}-#{index}", :password_confirmation => "#{role_name}-#{index}",
                    :approver_email => "super-admin@pcc-ishayoga.org", :message_to_approver => "Approve me", :enable => true )
    user.access_privileges.build(:role=>Role.where(:name=>::User::ROLE_ACCESS_HIERARCHY[role_name.to_sym][:text]).first,:resource=>zone)
    if not user.save
      puts " User #{user.email} not saved due to errros #{user.errors.messages} "
    end
  end
end

9.times do |index|
  sector=Sector.create(:name=>"Sector--#{index}", :zone=>Zone.find((index/3)+1))
  user = User.new(:firstname => "Sector Co-ordinator-#{index}",:email=> "sector-coordinator-#{index}@pcc-ishayoga.org",:mobile=>"9999999999",
                  :password => "sector-coordinator-#{index}", :password_confirmation => "sector-coordinator-#{index}",
                  :approver_email => "super-admin@pcc-ishayoga.org", :message_to_approver => "Approve me", :enable => true )
  user.access_privileges.build(:role=>Role.where(:name=>::User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]).first,:resource=>sector)
  if not user.save
    puts " User #{user.email} not saved due to errros #{user.errors.messages} "
  end
end

27.times do |index|
  center = Center.create(:name=>"Center--#{index}", :sector=>Sector.find((index/3)+1))
  Pincode.create(:pincode=>600000+index,:location_name=>"Pincode--#{index}",:center_id=>center.id)
  ["center_coordinator","volunteer_committee","center_scheduler","kit_coordinator","venue_coordinator","center_treasurer"].each do |role_name|
    user = User.new(:firstname => "#{role_name}-#{index}",:email=> "#{role_name}-#{index}@pcc-ishayoga.org",:mobile=>"9999999999",
                    :password => "#{role_name}-#{index}", :password_confirmation => "#{role_name}-#{index}",
                    :approver_email => "super-admin@pcc-ishayoga.org", :message_to_approver => "Approve me" , :enable => true  )
    user.access_privileges.build(:role=>Role.where(:name=>::User::ROLE_ACCESS_HIERARCHY[role_name.to_sym][:text]).first,:resource=>center)
    if not user.save
      puts " User #{user.email} not saved due to errros #{user.errors.messages} "
    end
  end
end

seed_data = YAML::load_file(File.join(Rails.root, 'db/seed-data', 'seed-data.yml'))
kit_items = seed_data["KitItemType"].collect do |kit_item_type|
  kt=KitItemType.where(:name=>kit_item_type).first
  KitItem.new(:description=>" Newly Purchased #{kit_item_type}", :condition=>"Good",:count=>3,:kit_item_type=>kt)
end

seed_data = YAML::load_file(File.join(Rails.root, 'db/seed-data', 'seed-data.yml'))
4.times do |index|
  kit=Kit.new(:condition=>"Good",:name=>"#{Sector.first.centers.first.name} - Kit", :guardian => Sector.first.centers.first.users.first ,:capacity=>50,:centers=>Sector.first.centers)
  if not kit.save
    puts " Kit #{kit.name} not saved due to  #{kit.errors.messages}"
  end
  seed_data["KitItemType"].collect do |kit_item_type|
    kit_item_type=KitItemType.where(:name=>kit_item_type).first
    kit_item = KitItem.new(:kit=>kit,:description=>" Newly Purchased #{kit_item_type}", :condition=>"Good",:count=>3,:kit_item_type=>kit_item_type)
    if not kit_item.save
      puts " Kit Item not saved due to  #{kit_item.errors.messages}"
    end
  end
end
4.times do |index|
  kit=Kit.new(:condition=>"Good",:name=>"#{Sector.find(2).centers.limit(2).first.name} - Kit", :guardian => Sector.find(2).centers.limit(2).first.users.first, :capacity=>50,:centers=>Sector.find(2).centers.limit(2))
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
  kit=Kit.new(:condition=>"Good",:name=>"#{Sector.first.centers.limit(1).first.name} - Kit", :guardian => Sector.first.centers.limit(1).first.users.first ,:capacity=>50,:centers=>Sector.first.centers.limit(1))
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
  kit=Kit.new(:condition=>"Good",:name=>"#{Sector.find(index+1).centers.first.name} - Kit", :guardian => Sector.find(index+1).centers.first.users.first , :capacity=>50,:centers=>Sector.find(index+1).centers)
  kit.save
  seed_data["KitItemType"].collect do |kit_item_type|
    kit_item_type=KitItemType.where(:name=>kit_item_type).first
    kit_item = KitItem.new(:kit=>kit,:description=>" Newly Purchased #{kit_item_type}",  :condition=>"Good",:count=>3,:kit_item_type=>kit_item_type)
    if not kit_item.save
      puts " Kit Item not saved due to  #{kit_item.errors.messages}"
    end
  end
end

7.times do |index|
  kit=Kit.new(:condition=>"Good",:name=>"#{Center.find(index+1).name} - Kit", :guardian => Center.find(index+1).users.first ,:capacity=>50,:centers=>[Center.find(index+1)])
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
  v = Venue.new(:name=>"#{Sector.last.centers.last.name} Venue", :commercial => true ,:capacity=>100,:contact_mobile=>9998908900,:pin_code => 560031, :per_day_price => 100, :address => " Venue Address", :centers => Sector.last.centers)
  if not v.save
    puts " Venue not saved due to  #{v.errors.messages}"
  end
end

4.times do |index|
  v=Venue.new(:name=>"#{Sector.first.centers.last.name} Venue", :commercial => true ,:capacity=>100,:contact_mobile=>9998908900,:pin_code => 560031, :per_day_price => 100, :address => "Venue Address", :centers => Sector.first.centers+Sector.last.centers )
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

Center.all.each do |center|
  v=Venue.new(:name=>"#{center.name} Venue", :commercial => true ,:capacity=>100,:contact_mobile=>9998908900,:pin_code => center.pincodes.last, :per_day_price => 100, :address => "Venue Address", :centers => [center])
  if not v.save
    puts " Venue not saved due to  #{v.errors.messages}"
  end
end

4.times do |index|
  user = User.new(:firstname => "Teacher-#{index}",:email=> "teacher-#{index}@pcc-ishayoga.org",:mobile=>"9999999999",
                  :password => "teacher-#{index}", :password_confirmation => "teacher-#{index}",
                  :approver_email => "super-admin@pcc-ishayoga.org", :message_to_approver => "Approve me",  :enable => true )
  user.save
  if not user.save
    puts "User #{user.firstname}  has not been saved because of #{user.errors.messages}"
  else
    zone=Zone.first
    teacher=Teacher.new(:t_no=>"1",:zone=>zone,:user=>user,:comments=>"Added for testing",:centers=>zone.centers.limit(3),:state=>Teacher::STATE_ATTACHED.to_s,:program_types=>ProgramType.all)
    if not teacher.save
      puts "Teacher #{user.firstname} has not been saved because of #{teacher.errors.messages}"
    end
  end
end
