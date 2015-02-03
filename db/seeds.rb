# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

  # create comments
  comments_yml = File.join(Rails.root, 'db/seed-data', 'comments.yml')
  YAML::load_file(comments_yml)["Comment"].each do |comment|
    c=Comment.find_or_initialize_by_model(comment[:model])
    c.attributes=(comment)
    if not c.save
      puts "Comment for model #{c.model} has not been saved because of #{c.errors.messages}"
    end
  end


  seed_data = YAML::load_file(File.join(Rails.root, 'db/seed-data', 'seed-data.yml'))

  #  create_default_permissions
  seed_data["Permission"].each do |permission|
    p=Permission.find_or_initialize_by_name(permission[:name])
    p.attributes=(permission)
    if not p.save
      puts "Permission #{p.name} has not been saved because of #{p.errors.messages}"
    end
  end

  #  create_default_kits
  seed_data["KitItemType"].each do |kit_item_type|
    k=KitItemType.find_or_initialize_by_name(:name=>kit_item_type)
    if not k.save
      puts "KitItemType #{k.name} has not been saved because of #{k.errors.messages}"
    end
  end


  # create Timing
  seed_data["Timing"].each do |timing|
    t=Timing.find_or_initialize_by_name(timing[:name])
    t.attributes=(timing)
    if not t.save
      puts "Timing #{t.name} has not been saved because of #{t.errors.messages}"
    end
  end

  # create program type
  seed_data["ProgramType"].each do |program_type|
    pt=ProgramType.find_or_initialize_by_name(program_type[:name])
    pt.attributes=(program_type)
    pt.timings = Timing.all
    if not pt.save
      puts "ProgramType #{pt.name} has not been saved because of #{pt.errors.messages}"
    end
  end

  # create program donation
  seed_data["ProgramDonation"].each do |program_donation|
    program_donation_name = program_donation["name"]
    pd=ProgramDonation.find_or_initialize_by_name(program_donation[:name])
    pd.attributes=(program_donation)
    program_type_name = program_donation_name.humanize.split[0..-2].join(" ")
    pd.program_type = ProgramType.where('lower(name) = ?', program_type_name.downcase).first
    if not pd.save
      puts "ProgramDonation #{pd.name} has not been saved because of #{pd.errors.messages}"
    end
  end


### Dummy users for all the roles used for testing purpose.
    user = User.new(:firstname => "Super Admin", :email=> "super-admin@pcc-ishayoga.org", :approver_email => "super-admin@pcc-ishayoga.org", :address=> "IYC", :mobile=>"9999999999", :password => "super_admin_123", :password_confirmation => "super_admin_123",:enable => true, :message_to_approver => "test" )
  puts "#### creating #{user.firstname} "
  user.access_privileges.build(:role=>Role.where(:name=>::User::ROLE_ACCESS_HIERARCHY[:super_admin][:text]).first)
  begin
    if not user.save(:validate => false)
      puts "User #{user.firstname} has not been saved because of #{user.errors.messages}"
    end
  rescue Errno::ECONNREFUSED
    puts "###################################"
    puts "rake aborted! \nErrno::ECONNREFUSED: Connection refused - connect(2)"
    puts "SMTP server not running. For developement environment, please start mailcatcher (http://mailcatcher.me/) and try again."
    puts "###################################"
  end

