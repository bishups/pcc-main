3.times do |index|
  zone=Zone.create(:name=>"Zone--#{index}")
  count = 0
  ["zonal_coordinator","zao", "pcc_accounts", "program_announcement", "finance_department", "teacher_training_department"].each do |role_name|
    count = count + 1
    user = User.new(:firstname => "#{role_name}-#{index}",:email=> "#{role_name}-#{index}@pcc-ishayoga.org",:mobile=> (9999999900 + index * 10 + count).to_s,
                    :password => "#{role_name}-#{index}", :password_confirmation => "#{role_name}-#{index}", :address => "Zone--#{index}",
                    :approver_email => "super-admin@pcc-ishayoga.org", :message_to_approver => "Approve me", :enable => true )
    user.access_privileges.build(:role=>Role.where(:name=>::User::ROLE_ACCESS_HIERARCHY[role_name.to_sym][:text]).first,:resource=>zone)
    if not user.save
      puts " User #{user.email} not saved due to errros #{user.errors.messages} "
    end
  end
end

9.times do |index|
  sector=Sector.create(:name=>"Sector--#{index}", :zone=>Zone.find((index/3)+1))
  user = User.new(:firstname => "Sector Co-ordinator-#{index}",:email=> "sector-coordinator-#{index}@pcc-ishayoga.org",:mobile=> (9999999000 + index).to_s,
                  :password => "sector-coordinator-#{index}", :password_confirmation => "sector-coordinator-#{index}", :address => "Sector--#{index}",
                  :approver_email => "super-admin@pcc-ishayoga.org", :message_to_approver => "Approve me", :enable => true )
  user.access_privileges.build(:role=>Role.where(:name=>::User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]).first,:resource=>sector)
  if not user.save
    puts " User #{user.email} not saved due to errros #{user.errors.messages} "
  end
end

27.times do |index|
  center = Center.create(:name=>"Center--#{index}", :sector=>Sector.find((index/3)+1), :program_donations=> [ProgramDonation.find((index/9)+1)])
  Pincode.create(:pincode=>600000+index,:location_name=>"Pincode--#{index}",:center_id=>center.id)
  count = 0
  ["center_coordinator","volunteer_committee","center_scheduler","kit_coordinator","venue_coordinator","treasurer"].each do |role_name|
    count = count + 1
    user = User.new(:firstname => "#{role_name}-#{index}",:email=> "#{role_name}-#{index}@pcc-ishayoga.org",:mobile=>(9999900000 + index * 1000 + count).to_s,
                    :password => "#{role_name}-#{index}", :password_confirmation => "#{role_name}-#{index}", :address => "Center--#{index}",
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
count = 0
4.times do |index|
  kit=Kit.new(:condition=>"Good",:name=>"#{Sector.first.centers.first.name} - Kit-#{count}", :guardian => Sector.first.centers.first.users.first ,:capacity=>50,:centers=>Sector.first.centers)
  count = count + 1
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

count = 0
4.times do |index|
  kit=Kit.new(:condition=>"Good",:name=>"#{Sector.find(2).centers.limit(2).first.name} - Kit-#{count}", :guardian => Sector.find(2).centers.limit(2).first.users.first, :capacity=>50,:centers=>Sector.find(2).centers.limit(2))
  count = count + 1
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

count = 0
4.times do |index|
  kit=Kit.new(:condition=>"Good",:name=>"#{Sector.first.centers.limit(1).first.name} - Kit-#{count}", :guardian => Sector.first.centers.limit(1).first.users.first ,:capacity=>50,:centers=>Sector.first.centers.limit(1))
  count = count + 1
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

count = 0
3.times do |index|
  kit=Kit.new(:condition=>"Good",:name=>"#{Sector.find(index+1).centers.first.name} - Kit-#{count}", :guardian => Sector.find(index+1).centers.first.users.first , :capacity=>50,:centers=>Sector.find(index+1).centers)
  count = count + 1
  if not kit.save
    puts " Kit #{kit.name} not saved due to  #{kit.errors.messages}"
  end
  seed_data["KitItemType"].collect do |kit_item_type|
    kit_item_type=KitItemType.where(:name=>kit_item_type).first
    kit_item = KitItem.new(:kit=>kit,:description=>" Newly Purchased #{kit_item_type}",  :condition=>"Good",:count=>3,:kit_item_type=>kit_item_type)
    if not kit_item.save
      puts " Kit Item not saved due to  #{kit_item.errors.messages}"
    end
  end
end

count = 0
7.times do |index|
  kit=Kit.new(:condition=>"Good",:name=>"#{Center.find(index+1).name} - Kit-#{count}", :guardian => Center.find(index+1).users.first ,:capacity=>50,:centers=>[Center.find(index+1)])
  count = count + 1
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

count = 0
4.times do |index|
  v = Venue.new(:name=>"#{Sector.last.centers.last.name} Venue-#{count}", :commercial => true ,:capacity=>100,:contact_mobile=>9998908900,:pincode => Sector.last.centers.last.pincodes.last, :per_day_price => 100, :address => " Venue Address", :centers => Sector.last.centers)
  count = count + 1
  if not v.save
    puts " Venue #{v.name} not saved due to  #{v.errors.messages}"
  end
end

count = 0
4.times do |index|
  v=Venue.new(:name=>"#{Sector.first.centers.last.name} Venue-#{count}", :commercial => true ,:capacity=>100,:contact_mobile=>9998908900,:pincode => Sector.first.centers.last.pincodes.last, :per_day_price => 100, :address => "Venue Address", :centers => Sector.first.centers+Sector.last.centers )
  count = count + 1
  if not v.save
    puts " Venue #{v.name} not saved due to  #{v.errors.messages}"
  end
end

count = 0
3.times do |index|
  v=Venue.new(:name=>"#{Sector.find(index+1).centers.first.name} Venue-#{count}", :commercial => true ,:capacity=>100,:contact_mobile=>9998908900,:pincode => Sector.find(index+1).centers.first.pincodes.first, :per_day_price => 100, :address => "Venue Address", :centers => Sector.find(index+1).centers)
  count = count + 1
  if not v.save
    puts "Venue #{v.name} not saved due to  #{v.errors.messages}"
  end
end

Center.all.each do |center|
  v=Venue.new(:name=>"#{center.name} Venue", :commercial => true ,:capacity=>100,:contact_mobile=>9998908900,:pincode => center.pincodes.last, :per_day_price => 100, :address => "Venue Address", :centers => [center])
  if not v.save
    puts " Venue #{v.name} not saved due to  #{v.errors.messages}"
  end
end

count = 0
4.times do |index|
  user = User.new(:firstname => "Teacher-#{index}",:email=> "teacher-#{index}@pcc-ishayoga.org",:mobile=>(9999000000 + index).to_s,
                  :password => "teacher-#{index}", :password_confirmation => "teacher-#{index}", :address => "IYC",
                  :approver_email => "super-admin@pcc-ishayoga.org", :message_to_approver => "Approve me",  :enable => true )
  user.save
  count = count + 1
  if not user.save
    puts "User #{user.firstname}  has not been saved because of #{user.errors.messages}"
  else
    zone=Zone.first
    teacher=Teacher.new(:t_no=>count.to_s,:zones=>[zone], :secondary_zones=>[], :user=>user,:comments=>"Added for testing",:centers=>zone.centers.limit(3),:state=>Teacher::STATE_ATTACHED.to_s,:program_types=>ProgramType.all)
    if not teacher.save
      puts "Teacher #{user.firstname} has not been saved because of #{teacher.errors.messages}"
    end
  end
end
