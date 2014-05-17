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



## create_default_roles
  roles={
    ::User::ROLE_ACCESS_HIERARCHY[:super_admin][:text] => ["Program Management","Teacher Scheduling","Kit Management","Venue Management"] ,
    ::User::ROLE_ACCESS_HIERARCHY[:zonal_coordinator][:text] => ["Program Management","Teacher Scheduling","Kit Management","Venue Management"] ,
    ::User::ROLE_ACCESS_HIERARCHY[:zao][:text] => ["Program Management","Teacher Scheduling","Kit Management","Venue Management"] ,
    ::User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text] => ["Program Management","Teacher Scheduling","Kit Management","Venue Management"] ,
    ::User::ROLE_ACCESS_HIERARCHY[:center_coordinator][:text] => ["Program Management","Teacher Scheduling","Kit Management","Venue Management"] ,
    ::User::ROLE_ACCESS_HIERARCHY[:center_scheduler][:text] =>  ["Program Management","Teacher Scheduling","Kit Management","Venue Management"] ,
    ::User::ROLE_ACCESS_HIERARCHY[:volunteer_committee][:text] => ["Program Management","Teacher View","Kit Management","Venue Management"] ,
    ::User::ROLE_ACCESS_HIERARCHY[:kit_coordinator][:text] => ["Program View","Teacher View","Kit Management","Venue Management"] ,
    ::User::ROLE_ACCESS_HIERARCHY[:venue_coordinator][:text] => ["Program View","Teacher View","Kit Management","Venue Management"] ,
    ::User::ROLE_ACCESS_HIERARCHY[:center_treasurer][:text] => ["Program View","Teacher View","Kit View","Venue View"],
    ::User::ROLE_ACCESS_HIERARCHY[:teacher][:text]  => ["Program View","Teacher Scheduling","Kit View","Venue View"],
    ::User::ROLE_ACCESS_HIERARCHY[:teacher_training_department][:text]  => ["Program View","Teacher Scheduling"],
    ::User::ROLE_ACCESS_HIERARCHY[:pcc_accounts][:text]  => ["Program Management","Venue Management"],
    ::User::ROLE_ACCESS_HIERARCHY[:finance_department][:text]  => ["Program View","Venue View"]
  }
  roles.each do |name,permissions|
    puts "####### #{name} --> #{permissions}"
    Role.create(:name=>name.to_s,:permissions=>Permission.find_all_by_name(permissions))
  end

# create notifications

zonal_coordinator = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:zonal_coordinator][:text])
zao = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:zao][:text])
sector_coordinator = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text])
center_coordinator = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:center_coordinator][:text])
volunteer_committee = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:volunteer_committee][:text])
center_scheduler = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:center_scheduler][:text])
kit_coordinator = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:kit_coordinator][:text])
venue_coordinator = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:venue_coordinator][:text])
center_treasurer = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:center_treasurer][:text])
teacher = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:teacher][:text])
teacher_training_department = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:teacher_training_department][:text])
pcc_accounts = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:pcc_accounts][:text])
finance_department = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:finance_department][:text])

notifications = [
    {:model => 'Program', :from_state => ::Program::STATE_UNKNOWN, :to_state => ::Program::STATE_PROPOSED, :on_event => ::Program::EVENT_PROPOSE, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_UNKNOWN, :to_state => ::Program::STATE_PROPOSED, :on_event => ::Program::EVENT_PROPOSE, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_UNKNOWN, :to_state => ::Program::STATE_PROPOSED, :on_event => ::Program::EVENT_PROPOSE, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_DROPPED, :on_event => ::Program::EVENT_DROP, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_DROPPED, :on_event => ::Program::EVENT_DROP, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_DROPPED, :on_event => ::Program::EVENT_DROP, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_EXPIRED, :on_event => 'any', :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Proposed Program Expired.' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_EXPIRED, :on_event => 'any', :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Proposed Program Expired.' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_EXPIRED, :on_event => 'any', :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => 'Proposed Program Expired.' },

    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_ANNOUNCED, :on_event => ::Program::EVENT_ANNOUNCE, :role_id =>  zonal_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_ANNOUNCED, :on_event => ::Program::EVENT_ANNOUNCE, :role_id =>  zao.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_ANNOUNCED, :on_event => ::Program::EVENT_ANNOUNCE, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_ANNOUNCED, :on_event => ::Program::EVENT_ANNOUNCE, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_ANNOUNCED, :on_event => ::Program::EVENT_ANNOUNCE, :role_id =>  volunteer_committee.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_ANNOUNCED, :on_event => ::Program::EVENT_ANNOUNCE, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_ANNOUNCED, :on_event => ::Program::EVENT_ANNOUNCE, :role_id =>  pcc_accounts.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_ANNOUNCED, :on_event => ::Program::EVENT_ANNOUNCE, :role_id =>  finance_department.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CANCELLED, :on_event => ::Program::EVENT_CANCEL, :role_id =>  zonal_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CANCELLED, :on_event => ::Program::EVENT_CANCEL, :role_id =>  zao.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CANCELLED, :on_event => ::Program::EVENT_CANCEL, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CANCELLED, :on_event => ::Program::EVENT_CANCEL, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CANCELLED, :on_event => ::Program::EVENT_CANCEL, :role_id =>  volunteer_committee.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CANCELLED, :on_event => ::Program::EVENT_CANCEL, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CANCELLED, :on_event => ::Program::EVENT_CANCEL, :role_id =>  pcc_accounts.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CANCELLED, :on_event => ::Program::EVENT_CANCEL, :role_id =>  finance_department.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Program', :from_state => ::Program::STATE_ANNOUNCED, :to_state => ::Program::STATE_REGISTRATION_OPEN, :on_event => ::Program::EVENT_CANCEL, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_ANNOUNCED, :to_state => ::Program::STATE_REGISTRATION_OPEN, :on_event => ::Program::EVENT_CANCEL, :role_id =>  volunteer_committee.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_ANNOUNCED, :to_state => ::Program::STATE_REGISTRATION_OPEN, :on_event => ::Program::EVENT_CANCEL, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Program', :from_state =>  'any', :to_state => ::Program::STATE_CONDUCTED, :on_event => 'any', :role_id =>  teacher.id, :send_sms => true, :send_email => true, :additional_text => 'Please enter feedback' },
    {:model => 'Program', :from_state =>  'any', :to_state => ::Program::STATE_TEACHER_CLOSED, :on_event => 'any', :role_id => zao.id, :send_sms => true, :send_email => true, :additional_text => 'Please mark as closed' },
    {:model => 'Program', :from_state =>  'any', :to_state => ::Program::STATE_ZAO_CLOSED, :on_event => 'any', :role_id => center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Please mark as closed' },

    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CLOSED, :on_event => 'any', :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CLOSED, :on_event => 'any', :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CLOSED, :on_event => 'any', :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Kit', :from_state => ::Kit::STATE_UNKNOWN, :to_state => ::Kit::STATE_AVAILABLE, :on_event => ::Kit::EVENT_AVAILABLE, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Kit', :from_state => ::Kit::STATE_UNKNOWN, :to_state => ::Kit::STATE_AVAILABLE, :on_event => ::Kit::EVENT_AVAILABLE, :role_id =>  volunteer_committee.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Kit', :from_state => ::Kit::STATE_UNKNOWN, :to_state => ::Kit::STATE_AVAILABLE, :on_event => ::Kit::EVENT_AVAILABLE, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Kit', :from_state => ::Kit::STATE_UNKNOWN, :to_state => ::Kit::STATE_AVAILABLE, :on_event => ::Kit::EVENT_AVAILABLE, :role_id =>  kit_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_UNAVAILABLE_OVERDUE, :on_event => ::KitSchedule::EVENT_UNAVAILABLE_OVERDUE, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_UNAVAILABLE_OVERDUE, :on_event => ::KitSchedule::EVENT_UNAVAILABLE_OVERDUE, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_UNAVAILABLE_OVERDUE, :on_event => ::KitSchedule::EVENT_UNAVAILABLE_OVERDUE, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_UNAVAILABLE_OVERDUE, :on_event => ::KitSchedule::EVENT_UNAVAILABLE_OVERDUE, :role_id =>  kit_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_RESERVED, :on_event => ::KitSchedule::EVENT_UNAVAILABLE_OVERDUE, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_RESERVED, :on_event => ::KitSchedule::EVENT_UNAVAILABLE_OVERDUE, :role_id =>  kit_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_UNDER_REPAIR, :on_event => ::KitSchedule::EVENT_UNDER_REPAIR, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_UNDER_REPAIR, :on_event => ::KitSchedule::EVENT_UNDER_REPAIR, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_UNDER_REPAIR, :on_event => ::KitSchedule::EVENT_UNDER_REPAIR, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_UNDER_REPAIR, :on_event => ::KitSchedule::EVENT_UNDER_REPAIR, :role_id =>  kit_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'KitSchedule', :from_state => 'any', :to_state => ::Kit::STATE_AVAILABLE, :on_event => ::KitSchedule::EVENT_DELETE, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => 'Kit available for block.' },
    {:model => 'KitSchedule', :from_state => 'any', :to_state => ::Kit::STATE_AVAILABLE, :on_event => ::KitSchedule::EVENT_DELETE, :role_id =>  kit_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Kit available for block.' },

    {:model => 'KitSchedule', :from_state => ::KitSchedule::STATE_BLOCKED, :to_state => ::KitSchedule::STATE_CANCELLED, :on_event => 'any', :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::KitSchedule::STATE_BLOCKED, :to_state => ::KitSchedule::STATE_CANCELLED, :on_event => 'any', :role_id =>  kit_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::KitSchedule::STATE_ASSIGNED, :to_state => ::KitSchedule::STATE_CANCELLED, :on_event => 'any', :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::KitSchedule::STATE_ASSIGNED, :to_state => ::KitSchedule::STATE_CANCELLED, :on_event => 'any', :role_id =>  kit_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'KitSchedule', :from_state => ::KitSchedule::STATE_ISSUED, :to_state => ::KitSchedule::STATE_OVERDUE, :on_event => ::KitSchedule::EVENT_OVERDUE, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::KitSchedule::STATE_ISSUED, :to_state => ::KitSchedule::STATE_OVERDUE, :on_event => ::KitSchedule::EVENT_OVERDUE, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::KitSchedule::STATE_ISSUED, :to_state => ::KitSchedule::STATE_OVERDUE, :on_event => ::KitSchedule::EVENT_OVERDUE, :role_id =>  kit_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'KitSchedule', :from_state => 'any', :to_state => ::KitSchedule::STATE_AVAILABLE_EXPIRED, :on_event => 'any', :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Blocked Kit Not Used.' },
    {:model => 'KitSchedule', :from_state => 'any', :to_state => ::KitSchedule::STATE_AVAILABLE_EXPIRED, :on_event => 'any', :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Blocked Kit Not Used.' },
    {:model => 'KitSchedule', :from_state => 'any', :to_state => ::KitSchedule::STATE_AVAILABLE_EXPIRED, :on_event => 'any', :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => 'Blocked Kit Not Used.' },
    {:model => 'KitSchedule', :from_state => 'any', :to_state => ::KitSchedule::STATE_AVAILABLE_EXPIRED, :on_event => 'any', :role_id =>  kit_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Blocked Kit Not Used.' },

    {:model => 'Venue', :from_state => ::Venue::STATE_UNKNOWN, :to_state => ::Venue::STATE_PROPOSED, :on_event => ::Venue::EVENT_PROPOSE, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Venue pending your approval.' },

    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_APPROVED, :on_event => 'any', :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_APPROVED, :on_event => 'any', :role_id =>  venue_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_PENDING_FINANCE_APPROVAL, :on_event => ::Venue::EVENT_REQUEST_FINANCE_APPROVAL, :role_id =>  finance_department.id, :send_sms => true, :send_email => true, :additional_text => 'Venue pending your approval' },
    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_PENDING_FINANCE_APPROVAL, :on_event => ::Venue::EVENT_REQUEST_FINANCE_APPROVAL, :role_id =>  pcc_accounts.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_POSSIBLE, :on_event => 'any', :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_POSSIBLE, :on_event => 'any', :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_POSSIBLE, :on_event => 'any',:role_id =>  volunteer_committee.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_POSSIBLE, :on_event => 'any',:role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_POSSIBLE, :on_event => 'any',:role_id =>  venue_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_REJECTED, :on_event => 'any', :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_REJECTED, :on_event => 'any', :role_id =>  venue_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Venue', :from_state => 'any', :to_state => 'any', :on_event => ::Venue::EVENT_PER_DAY_PRICE_CHANGE, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Check if finance approval needed.' },

    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_UNKNOWN, :to_state => ::VenueSchedule::STATE_BLOCK_REQUESTED, :on_event => ::VenueSchedule::EVENT_BLOCK_REQUEST, :role_id =>  venue_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Request pending your approval.' },
    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_UNKNOWN, :to_state => ::VenueSchedule::STATE_BLOCK_REQUESTED, :on_event => ::VenueSchedule::EVENT_BLOCK_REQUEST, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'VenueSchedule', :from_state => 'any', :to_state => ::VenueSchedule::STATE_BLOCK_REQUESTED, :on_event => ::VenueSchedule::EVENT_BLOCK_EXPIRED, :role_id =>  venue_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Venue Block Expired !' },
    {:model => 'VenueSchedule', :from_state => 'any', :to_state => ::VenueSchedule::STATE_BLOCK_REQUESTED, :on_event => ::VenueSchedule::EVENT_BLOCK_EXPIRED, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => 'Venue Block Expired !' },
    {:model => 'VenueSchedule', :from_state => 'any', :to_state => ::VenueSchedule::STATE_BLOCK_REQUESTED, :on_event => ::VenueSchedule::EVENT_BLOCK_EXPIRED, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Venue Block Expired !' },
    {:model => 'VenueSchedule', :from_state => 'any', :to_state => ::VenueSchedule::STATE_BLOCK_REQUESTED, :on_event => ::VenueSchedule::EVENT_BLOCK_EXPIRED, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Venue Block Expired !' },
    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_PAYMENT_PENDING, :to_state => ::VenueSchedule::STATE_BLOCK_REQUESTED, :on_event => ::VenueSchedule::EVENT_BLOCK_EXPIRED, :role_id =>  pcc_accounts.id, :send_sms => true, :send_email => true, :additional_text => 'Venue Block Expired. Please Cancel Payment Request.' },
    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_PAYMENT_PENDING, :to_state => ::VenueSchedule::STATE_BLOCK_REQUESTED, :on_event => ::VenueSchedule::EVENT_BLOCK_EXPIRED, :role_id =>  finance_department.id, :send_sms => true, :send_email => true, :additional_text => 'Venue Block Expired. Please Cancel Payment Request.' },

    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_BLOCK_REQUESTED, :to_state => ::VenueSchedule::STATE_BLOCKED, :on_event => ::VenueSchedule::EVENT_BLOCK, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_BLOCK_REQUESTED, :to_state => ::VenueSchedule::STATE_UNAVAILABLE, :on_event => ::VenueSchedule::EVENT_REJECT, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'VenueSchedule', :from_state => 'any', :to_state => ::VenueSchedule::STATE_CANCELLED, :on_event => 'any', :role_id =>  venue_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_BLOCKED, :to_state => ::VenueSchedule::STATE_APPROVAL_REQUESTED, :on_event => ::VenueSchedule::EVENT_REQUEST_APPROVAL, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Venue schedule pending your approval.' },

    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_APPROVAL_REQUESTED, :to_state => ::VenueSchedule::STATE_AUTHORIZED_FOR_PAYMENT, :on_event => ::VenueSchedule::EVENT_AUTHORIZE_FOR_PAYMENT, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_APPROVAL_REQUESTED, :to_state => ::VenueSchedule::STATE_AUTHORIZED_FOR_PAYMENT, :on_event => ::VenueSchedule::EVENT_AUTHORIZE_FOR_PAYMENT, :role_id =>  venue_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_AUTHORIZED_FOR_PAYMENT, :to_state => ::VenueSchedule::STATE_PAYMENT_PENDING, :on_event => ::VenueSchedule::EVENT_REQUEST_PAYMENT, :role_id =>  pcc_accounts.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_AUTHORIZED_FOR_PAYMENT, :to_state => ::VenueSchedule::STATE_PAYMENT_PENDING, :on_event => ::VenueSchedule::EVENT_REQUEST_PAYMENT, :role_id =>  finance_department.id, :send_sms => true, :send_email => true, :additional_text => 'Venue Schedule pending your approval.' },

    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_AUTHORIZED_FOR_PAYMENT, :to_state => ::VenueSchedule::STATE_PAID, :on_event => ::VenueSchedule::EVENT_PAID, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_AUTHORIZED_FOR_PAYMENT, :to_state => ::VenueSchedule::STATE_PAID, :on_event => ::VenueSchedule::EVENT_PAID, :role_id =>  venue_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_IN_PROGRESS, :to_state => ::VenueSchedule::STATE_CONDUCTED, :on_event => 'any', :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_IN_PROGRESS, :to_state => ::VenueSchedule::STATE_CONDUCTED, :on_event => 'any', :role_id =>  venue_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'VenueSchedule', :from_state => 'any', :to_state => ::VenueSchedule::STATE_AVAILABLE_EXPIRED, :on_event => 'any', :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Blocked Venue Not Used !' },
    {:model => 'VenueSchedule', :from_state => 'any', :to_state => ::VenueSchedule::STATE_AVAILABLE_EXPIRED, :on_event => 'any', :role_id =>  venue_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Blocked Venue Not Used !' },
    {:model => 'VenueSchedule', :from_state => 'any', :to_state => ::VenueSchedule::STATE_AVAILABLE_EXPIRED, :on_event => 'any', :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => 'Blocked Venue Not Used !' },
    {:model => 'VenueSchedule', :from_state => 'any', :to_state => ::VenueSchedule::STATE_AVAILABLE_EXPIRED, :on_event => 'any', :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Blocked Venue Not Used !' },
    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_PAYMENT_PENDING, :to_state => ::VenueSchedule::STATE_AVAILABLE_EXPIRED, :on_event => 'any', :role_id =>  pcc_accounts.id, :send_sms => true, :send_email => true, :additional_text => 'Venue Block Expired. Please Cancel Payment Request.' },
    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_PAYMENT_PENDING, :to_state => ::VenueSchedule::STATE_AVAILABLE_EXPIRED, :on_event => 'any', :role_id =>  finance_department.id, :send_sms => true, :send_email => true, :additional_text => 'Venue Block Expired. Please Cancel Payment Request.' },

    {:model => 'VenueSchedule', :from_state => 'any', :to_state => ::VenueSchedule::STATE_EXPIRED, :on_event => 'any', :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'VenueSchedule', :from_state => 'any', :to_state => ::VenueSchedule::STATE_EXPIRED, :on_event => 'any', :role_id =>  venue_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'VenueSchedule', :from_state => 'any', :to_state => ::VenueSchedule::STATE_EXPIRED, :on_event => 'any', :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Teacher', :from_state => 'any', :to_state => ::Teacher::STATE_ATTACHED, :on_event => 'any', :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Teacher', :from_state => 'any', :to_state => ::Teacher::STATE_ATTACHED, :on_event => 'any', :role_id =>  teacher.id, :send_sms => true, :send_email => true, :additional_text => 'Please publish schedule.' },

    {:model => 'ProgramTeacherSchedule', :from_state => 'any', :to_state => ::ProgramTeacherSchedule::STATE_RELEASE_REQUESTED, :on_event => ::ProgramTeacherSchedule::EVENT_REQUEST_RELEASE, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Request pending your approval.' },
    {:model => 'ProgramTeacherSchedule', :from_state => ::ProgramTeacherSchedule::STATE_RELEASE_REQUESTED, :to_state => ::TeacherSchedule::STATE_UNAVAILABLE, :on_event => ::ProgramTeacherSchedule::EVENT_RELEASE, :role_id =>  teacher.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'TeacherSchedule', :from_state => 'any', :to_state => ::TeacherSchedule::STATE_AVAILABLE_EXPIRED, :on_event => 'any', :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Blocked Teacher Not Used !' },
    {:model => 'TeacherSchedule', :from_state => 'any', :to_state => ::TeacherSchedule::STATE_AVAILABLE_EXPIRED, :on_event => 'any', :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Blocked Teacher Not Used !' },
    {:model => 'TeacherSchedule', :from_state => 'any', :to_state => ::TeacherSchedule::STATE_AVAILABLE_EXPIRED, :on_event => 'any', :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => 'Blocked Teacher Not Used !' }

]
notifications.each{|n| Notification.create(n)}


### Dummy users for all the roles used for testing purpose.
  user = User.new(:firstname => "Super Admin", :email=> "super-admin@pcc-ishayoga.org", :address=> "IYC", :mobile=>"9999999999", :password => "super_admin_123", :password_confirmation => "super_admin_123",:enable => true )
  user.access_privileges.build(:role=>Role.where(:name=>::User::ROLE_ACCESS_HIERARCHY[:super_admin][:text]).first)
  user.save(:validate => false)


