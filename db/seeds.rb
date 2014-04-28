# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)



  # create comments
  comments = [
    {:model => 'Program', :action => ::Program::EVENT_DROP, :text => 'Venue not available'},
    {:model => 'Program', :action => ::Program::EVENT_DROP, :text => 'Teacher not available'},
    {:model => 'Program', :action => ::Program::EVENT_DROP, :text => 'Kit not available'},
    {:model => 'Program', :action => ::Program::EVENT_DROP, :text => 'Volunteers not available'},
    {:model => 'Program', :action => ::Program::EVENT_DROP, :text => 'Other'},
    {:model => 'Program', :action => ::Program::EVENT_CANCEL, :text => 'Venue not available'},
    {:model => 'Program', :action => ::Program::EVENT_CANCEL, :text => 'Teacher not available'},
    {:model => 'Program', :action => ::Program::EVENT_CANCEL, :text => 'Kit not available'},
    {:model => 'Program', :action => ::Program::EVENT_CANCEL, :text => 'Volunteers not available'},
    {:model => 'Program', :action => ::Program::EVENT_CANCEL, :text => 'Other'},
    {:model => 'Program', :action => ::Program::EVENT_ZAO_CLOSE, :text => 'Account closed. Participant data entered.'},
    {:model => 'Program', :action => ::Program::EVENT_ZAO_CLOSE, :text => 'Other'},

    {:model => 'Teacher', :action => ::Teacher::EVENT_UNFIT, :text => 'Physical ailments'},
    {:model => 'Teacher', :action => ::Teacher::EVENT_UNFIT, :text => 'Not suitable'},
    {:model => 'Teacher', :action => ::Teacher::EVENT_UNFIT, :text => 'Needs additional training'},
    {:model => 'Teacher', :action => ::Teacher::EVENT_UNFIT, :text => 'Other'},
    {:model => 'Teacher', :action => ::Teacher::EVENT_UNATTACH, :text => 'Unfit'},
    {:model => 'Teacher', :action => ::Teacher::EVENT_UNATTACH, :text => 'Relocating to other zone'},
    {:model => 'Teacher', :action => ::Teacher::EVENT_UNATTACH, :text => 'Need retraining'},
    {:model => 'Teacher', :action => ::Teacher::EVENT_UNATTACH, :text => 'Other'},

    {:model => 'ProgramTeacherSchedule', :action => ::ProgramTeacherSchedule::EVENT_RELEASE, :text => 'Teacher requested release'},
    {:model => 'ProgramTeacherSchedule', :action => ::ProgramTeacherSchedule::EVENT_RELEASE, :text => 'Needed for other schedule'},
    {:model => 'ProgramTeacherSchedule', :action => ::ProgramTeacherSchedule::EVENT_RELEASE, :text => 'Unwell'},
    {:model => 'ProgramTeacherSchedule', :action => ::ProgramTeacherSchedule::EVENT_RELEASE, :text => 'Unfit'},
    {:model => 'ProgramTeacherSchedule', :action => ::ProgramTeacherSchedule::EVENT_RELEASE, :text => 'Other'},
    {:model => 'ProgramTeacherSchedule', :action => ::ProgramTeacherSchedule::EVENT_WITHDRAW, :text => 'Teacher requested release'},
    {:model => 'ProgramTeacherSchedule', :action => ::ProgramTeacherSchedule::EVENT_WITHDRAW, :text => 'Needed for other schedule'},
    {:model => 'ProgramTeacherSchedule', :action => ::ProgramTeacherSchedule::EVENT_WITHDRAW, :text => 'Unwell'},
    {:model => 'ProgramTeacherSchedule', :action => ::ProgramTeacherSchedule::EVENT_WITHDRAW, :text => 'Unfit'},
    {:model => 'ProgramTeacherSchedule', :action => ::ProgramTeacherSchedule::EVENT_WITHDRAW, :text => 'Other'},
    {:model => 'ProgramTeacherSchedule', :action => ::ProgramTeacherSchedule::EVENT_REQUEST_RELEASE, :text => 'Unwell'},
    {:model => 'ProgramTeacherSchedule', :action => ::ProgramTeacherSchedule::EVENT_REQUEST_RELEASE, :text => 'Emergency'},
    {:model => 'ProgramTeacherSchedule', :action => ::ProgramTeacherSchedule::EVENT_REQUEST_RELEASE, :text => 'Other'},

    {:model => 'KitSchedule', :action => ::KitSchedule::EVENT_CANCEL, :text => 'Other Kit arranged'},
    {:model => 'KitSchedule', :action => ::KitSchedule::EVENT_CANCEL, :text => 'Other'},
    {:model => 'KitSchedule', :action => ::KitSchedule::EVENT_UNDER_REPAIR, :text => 'Kit Item under repair'},
    {:model => 'KitSchedule', :action => ::KitSchedule::EVENT_UNDER_REPAIR, :text => 'Kit Item under replacement'},
    {:model => 'KitSchedule', :action => ::KitSchedule::EVENT_UNDER_REPAIR, :text => 'Adding new kit items'},
    {:model => 'KitSchedule', :action => ::KitSchedule::EVENT_UNDER_REPAIR, :text => 'Other'},
    {:model => 'KitSchedule', :action => ::KitSchedule::EVENT_UNAVAILABLE_OVERDUE, :text => 'Not returned'},
    {:model => 'KitSchedule', :action => ::KitSchedule::EVENT_UNAVAILABLE_OVERDUE, :text => 'Other'},
    {:model => 'KitSchedule', :action => ::KitSchedule::EVENT_RESERVE, :text => 'Reserved for other program'},
    {:model => 'KitSchedule', :action => ::KitSchedule::EVENT_RESERVE, :text => 'Other'},
    {:model => 'KitSchedule', :action => ::KitSchedule::EVENT_RETURNED, :text => 'Issued Condition'},
    {:model => 'KitSchedule', :action => ::KitSchedule::EVENT_RETURNED, :text => 'Damaged'},
    {:model => 'KitSchedule', :action => ::KitSchedule::EVENT_RETURNED, :text => 'Other'},
    {:model => 'KitSchedule', :action => ::KitSchedule::EVENT_CLOSE, :text => 'Kit not suitable'},
    {:model => 'KitSchedule', :action => ::KitSchedule::EVENT_CLOSE, :text => 'Other'},

    {:model => 'Venue', :action => ::Venue::EVENT_REJECT, :text => 'Venue not suitable'},
    {:model => 'Venue', :action => ::Venue::EVENT_REJECT, :text => 'Rent too high'},
    {:model => 'Venue', :action => ::Venue::EVENT_REJECT, :text => 'Other'},

    {:model => 'VenueSchedule', :action => ::VenueSchedule::EVENT_REJECT, :text => 'Venue not available'},
    {:model => 'VenueSchedule', :action => ::VenueSchedule::EVENT_REJECT, :text => 'Other'},
    {:model => 'VenueSchedule', :action => ::VenueSchedule::EVENT_CANCEL, :text => 'Other Venue arranged'},
    {:model => 'VenueSchedule', :action => ::VenueSchedule::EVENT_CANCEL, :text => 'Venue not suitable'},
    {:model => 'VenueSchedule', :action => ::VenueSchedule::EVENT_CANCEL, :text => 'Other'},
    {:model => 'VenueSchedule', :action => ::VenueSchedule::EVENT_SECURITY_REFUNDED, :text => 'Paid and Security Refunded'},
    {:model => 'VenueSchedule', :action => ::VenueSchedule::EVENT_SECURITY_REFUNDED, :text => 'Other'},
    {:model => 'VenueSchedule', :action => ::VenueSchedule::EVENT_CLOSE, :text => 'Venue not suitable'},
    {:model => 'VenueSchedule', :action => ::VenueSchedule::EVENT_CLOSE, :text => 'Other'},

  ]
  comments.each{|c| Comment.create(c) }


#  create_default_permissions
  permissions = [
      { :name => "Program Management", :cancan_action => "manage", :subject => "Program"},
      { :name => "Teacher Scheduling", :cancan_action => "update", :subject => "Teacher"},
      { :name => "Kit Management", :cancan_action => "manage", :subject => "Kit"},
      { :name => "Venue Management", :cancan_action => "manage", :subject => "Venue"},
      { :name => "Teacher View", :cancan_action => "read", :subject => "Teacher"},
      { :name => "Program View", :cancan_action => "read", :subject => "Program"},
      { :name => "Kit View", :cancan_action => "read", :subject => "Kit"},
      { :name => "Venue View", :cancan_action => "read", :subject => "Venue"},
      { :name => "Master Data Management", :cancan_action => "manage", :subject => :all}
  ]
  permissions.each{|p| Permission.create(p) }

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
pcc_accounts = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:pcc_accounts][:text])
finance_department = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:finance_department][:text])

notifications = [
    {:model => 'Program', :from_state => ::Program::STATE_UNKNOWN, :to_state => ::Program::STATE_PROPOSED, :on_event => ::Program::EVENT_PROPOSE, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_UNKNOWN, :to_state => ::Program::STATE_PROPOSED, :on_event => ::Program::EVENT_PROPOSE, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_UNKNOWN, :to_state => ::Program::STATE_PROPOSED, :on_event => ::Program::EVENT_PROPOSE, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_DROPPED, :on_event => ::Program::EVENT_DROP, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_DROPPED, :on_event => ::Program::EVENT_DROP, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_DROPPED, :on_event => ::Program::EVENT_DROP, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_ANNOUNCED, :on_event => ::Program::EVENT_ANNOUNCE, :role_id =>  zonal_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_ANNOUNCED, :on_event => ::Program::EVENT_ANNOUNCE, :role_id =>  zao.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_ANNOUNCED, :on_event => ::Program::EVENT_ANNOUNCE, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_ANNOUNCED, :on_event => ::Program::EVENT_ANNOUNCE, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_ANNOUNCED, :on_event => ::Program::EVENT_ANNOUNCE, :role_id =>  volunteer_committee.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_ANNOUNCED, :on_event => ::Program::EVENT_ANNOUNCE, :role_id =>  pcc_accounts.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_PROPOSED, :to_state => ::Program::STATE_ANNOUNCED, :on_event => ::Program::EVENT_ANNOUNCE, :role_id =>  finance_department.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CANCELLED, :on_event => ::Program::EVENT_CANCEL, :role_id =>  zonal_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CANCELLED, :on_event => ::Program::EVENT_CANCEL, :role_id =>  zao.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CANCELLED, :on_event => ::Program::EVENT_CANCEL, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CANCELLED, :on_event => ::Program::EVENT_CANCEL, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CANCELLED, :on_event => ::Program::EVENT_CANCEL, :role_id =>  volunteer_committee.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CANCELLED, :on_event => ::Program::EVENT_CANCEL, :role_id =>  pcc_accounts.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CANCELLED, :on_event => ::Program::EVENT_CANCEL, :role_id =>  finance_department.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Program', :from_state => ::Program::STATE_ANNOUNCED, :to_state => ::Program::STATE_REGISTRATION_OPEN, :on_event => ::Program::EVENT_CANCEL, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => ::Program::STATE_ANNOUNCED, :to_state => ::Program::STATE_REGISTRATION_OPEN, :on_event => ::Program::EVENT_CANCEL, :role_id =>  volunteer_committee.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Program', :from_state =>  'any', :to_state => ::Program::STATE_CONDUCTED, :on_event => 'any', :role_id =>  teacher.id, :send_sms => true, :send_email => true, :additional_text => 'Please enter feedback' },

    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CLOSED, :on_event => 'any', :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CLOSED, :on_event => 'any', :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Program', :from_state => 'any', :to_state => ::Program::STATE_CLOSED, :on_event => 'any', :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Kit', :from_state => ::Kit::STATE_UNKNOWN, :to_state => ::Kit::STATE_AVAILABLE, :on_event => ::Kit::EVENT_AVAILABLE, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Kit', :from_state => ::Kit::STATE_UNKNOWN, :to_state => ::Kit::STATE_AVAILABLE, :on_event => ::Kit::EVENT_AVAILABLE, :role_id =>  volunteer_committee.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_UNAVAILABLE_OVERDUE, :on_event => ::KitSchedule::EVENT_UNAVAILABLE_OVERDUE, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_UNAVAILABLE_OVERDUE, :on_event => ::KitSchedule::EVENT_UNAVAILABLE_OVERDUE, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_UNAVAILABLE_OVERDUE, :on_event => ::KitSchedule::EVENT_UNAVAILABLE_OVERDUE, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_UNAVAILABLE_OVERDUE, :on_event => ::KitSchedule::EVENT_UNAVAILABLE_OVERDUE, :role_id =>  kit_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_UNDER_REPAIR, :on_event => ::KitSchedule::EVENT_UNDER_REPAIR, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_UNDER_REPAIR, :on_event => ::KitSchedule::EVENT_UNDER_REPAIR, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_UNDER_REPAIR, :on_event => ::KitSchedule::EVENT_UNDER_REPAIR, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::Kit::STATE_AVAILABLE, :to_state => ::KitSchedule::STATE_UNDER_REPAIR, :on_event => ::KitSchedule::EVENT_UNDER_REPAIR, :role_id =>  kit_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'KitSchedule', :from_state => ::KitSchedule::STATE_BLOCKED, :to_state => ::KitSchedule::STATE_CANCELLED, :on_event => 'any', :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::KitSchedule::STATE_BLOCKED, :to_state => ::KitSchedule::STATE_CANCELLED, :on_event => 'any', :role_id =>  kit_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::KitSchedule::STATE_ASSIGNED, :to_state => ::KitSchedule::STATE_CANCELLED, :on_event => 'any', :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::KitSchedule::STATE_ASSIGNED, :to_state => ::KitSchedule::STATE_CANCELLED, :on_event => 'any', :role_id =>  kit_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'KitSchedule', :from_state => ::KitSchedule::STATE_ISSUED, :to_state => ::KitSchedule::STATE_OVERDUE, :on_event => ::KitSchedule::EVENT_OVERDUE, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::KitSchedule::STATE_ISSUED, :to_state => ::KitSchedule::STATE_OVERDUE, :on_event => ::KitSchedule::EVENT_OVERDUE, :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'KitSchedule', :from_state => ::KitSchedule::STATE_ISSUED, :to_state => ::KitSchedule::STATE_OVERDUE, :on_event => ::KitSchedule::EVENT_OVERDUE, :role_id =>  kit_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Venue', :from_state => ::Venue::STATE_UNKNOWN, :to_state => ::Venue::STATE_PROPOSED, :on_event => ::Venue::EVENT_PROPOSE, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Venue pending your approval.' },

    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_APPROVED, :on_event => 'any', :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_APPROVED, :on_event => 'any', :role_id =>  venue_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_PENDING_FINANCE_APPROVAL, :on_event => ::Venue::EVENT_REQUEST_FINANCE_APPROVAL, :role_id =>  finance_department.id, :send_sms => true, :send_email => true, :additional_text => 'Venue pending your approval' },
    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_PENDING_FINANCE_APPROVAL, :on_event => ::Venue::EVENT_REQUEST_FINANCE_APPROVAL, :role_id =>  pcc_accounts.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_POSSIBLE, :on_event => 'any', :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_POSSIBLE, :on_event => 'any', :role_id =>  center_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_POSSIBLE, :on_event => 'any',:role_id =>  volunteer_committee.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_REJECTED, :on_event => 'any', :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Venue', :from_state => 'any', :to_state => ::Venue::STATE_REJECTED, :on_event => 'any', :role_id =>  venue_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_UNKNOWN, :to_state => ::VenueSchedule::STATE_BLOCK_REQUESTED, :on_event => ::VenueSchedule::EVENT_BLOCK_REQUEST, :role_id =>  venue_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Request pending your approval.' },
    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_UNKNOWN, :to_state => ::VenueSchedule::STATE_BLOCK_REQUESTED, :on_event => ::VenueSchedule::EVENT_BLOCK_REQUEST, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'VenueSchedule', :from_state => 'any', :to_state => ::VenueSchedule::STATE_BLOCK_REQUESTED, :on_event => ::VenueSchedule::EVENT_BLOCK_EXPIRED, :role_id =>  venue_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Venue Block Expired.' },
    {:model => 'VenueSchedule', :from_state => 'any', :to_state => ::VenueSchedule::STATE_BLOCK_REQUESTED, :on_event => ::VenueSchedule::EVENT_BLOCK_EXPIRED, :role_id =>  center_scheduler.id, :send_sms => true, :send_email => true, :additional_text => 'Venue Block Expired.' },

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

    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_IN_PROGRESS, :to_state => ::VenueSchedule::STATE_CONDUCTED, :on_event => 'any', :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'VenueSchedule', :from_state => ::VenueSchedule::STATE_IN_PROGRESS, :to_state => ::VenueSchedule::STATE_CONDUCTED, :on_event => 'any', :role_id =>  venue_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },

    {:model => 'Teacher', :from_state => 'any', :to_state => ::Teacher::STATE_ATTACHED, :on_event => 'any', :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => '' },
    {:model => 'Teacher', :from_state => 'any', :to_state => ::Teacher::STATE_ATTACHED, :on_event => 'any', :role_id =>  teacher.id, :send_sms => true, :send_email => true, :additional_text => 'Please publish schedule.' },

    {:model => 'ProgramTeacherSchedule', :from_state => 'any', :to_state => ::ProgramTeacherSchedule::STATE_RELEASE_REQUESTED, :on_event => ::ProgramTeacherSchedule::EVENT_REQUEST_RELEASE, :role_id =>  sector_coordinator.id, :send_sms => true, :send_email => true, :additional_text => 'Request pending your approval.' },
    {:model => 'ProgramTeacherSchedule', :from_state => ::ProgramTeacherSchedule::STATE_RELEASE_REQUESTED, :to_state => ::TeacherSchedule::STATE_UNAVAILABLE, :on_event => ::ProgramTeacherSchedule::EVENT_RELEASE, :role_id =>  teacher.id, :send_sms => true, :send_email => true, :additional_text => '' }
]
notifications.each{|n| Notification.create(n) }

  ### Add a dummy user
  user=User.find_or_initialize_by_email("test@ishadb.com")
  user.firstname= "test"
  user.password= "test123"
  user.password_confirmation = "test123"
  user.mobile = 9999999999
  user.save
  if not user.save
    puts "User #{user.firstname} has not been saved because of #{user.errors.messages}"
  end

  item = KitItem.find_or_initialize_by_kit_item_name("Carpet")
  if not item.save
    puts "User #{item.kit_item_name} has not been saved because of #{kititem.errors.messages}"
  end
  item = KitItem.find_or_initialize_by_kit_item_name_id("Sadhguru Photo")
  if not item.save
    puts "User #{item.kit_item_name} has not been saved because of #{kititem.errors.messages}"
  end

  #timing = Timing.find_or_initialize_by_name("Morning (6am-9am)")
  #timing = Timing.find_or_initialize_by_name("Afternoon (10am-1pm)")
  #timing = Timing.find_or_initialize_by_name("Evening (2pm-5pm)")
  #timing = Timing.find_or_initialize_by_name("Night (6pm-9pm)")



# create geo_graphical_locations
  workbook = RubyXL::Parser.parse("master-data.xlsx")
  sheet=workbook["Centre-Sector-Zone"].get_table
  sheet[:table].each do |row|

    ####### Creating or Finding a Zone #######

    zone=Zone.find_or_create_by_name(row["Zone"])
    zonal_coordinator = User.find_or_initialize_by_email(row["Email Id  Isha Zonal Coordinator"].strip)
    if zonal_coordinator.new_record?
      zonal_coordinator.firstname =row["Name  Isha Zonal Coordinator"]
      zonal_coordinator.mobile=row["Contact No  Isha Zonal Coordinator"]
      zonal_coordinator.address = " "
      zonal_coordinator.access_privileges.build(:role=>Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:zonal_coordinator][:text]),:resource=>zone)
    elsif not zonal_coordinator.access_to_resource?(zone)
      zonal_coordinator.access_privileges.build(:role=>Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:zonal_coordinator][:text]),:resource=>zone)
    end
    zonal_coordinator.password = zonal_coordinator.firstname.squeeze.gsub(" ","_") if zonal_coordinator.firstname
    zonal_coordinator.password_confirmation = zonal_coordinator.firstname.squeeze.gsub(" ","_") if zonal_coordinator.firstname
    if not zonal_coordinator.save
      puts "Zonal cooridnator for #{zone.name} has not been saved because of  #{zonal_coordinator.errors.messages}"
    end
    ####### Creating or Finding a Sector #######

    sector=Sector.find_or_create_by_name_and_zone_id(row["Isha Sector"].strip,zone.id)
    sector_coordinator = User.find_or_initialize_by_email(row["Name - Isha Sector Coordinator"].downcase.squeeze.gsub(" ","-")+"@ishafoundation.org")
    if sector_coordinator.new_record?
      sector_coordinator.firstname= row["Name - Isha Sector Coordinator"]
      sector_coordinator.mobile= " "
      sector_coordinator.address = " "

      sector_coordinator.access_privileges.build(:role=>Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]),:resource=>sector)
    elsif not sector_coordinator.access_to_resource?(sector)
      sector_coordinator.access_privileges.build(:role=>Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]),:resource=>sector)
    end
    sector_coordinator.password = sector_coordinator.firstname.squeeze.gsub(" ","_")  if sector_coordinator.firstname
    sector_coordinator.password_confirmation = sector_coordinator.firstname.squeeze.gsub(" ","_") if sector_coordinator.firstname
    if not sector_coordinator.save
      puts "Sector cooridnator for #{sector.name} has not been saved becuase of  #{sector_coordinator.errors.messages}"
    end

    ####### Creating or Finding a Center #######

    center=Center.find_or_create_by_name_and_sector_id(row["Isha Center"].strip,sector.id)
    center.pincodes.build(:pincode => row["Pincode"],:location_name => row["Isha Center"])
    center_coordinator = User.find_or_initialize_by_email(row["Email Id - Isha Center Coordinator"])
    if center_coordinator.new_record?
      center_coordinator.firstname= row["Name - Isha Center Coordinator"]
      center_coordinator.mobile= row["Contact No - Isha Center Coordinator"]
      center_coordinator.address = row["Address - Isha Center Coordinator"]
      center_coordinator.access_privileges.build(:role=>Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:center_coordinator][:text]),:resource=>center)
    elsif not center_coordinator.access_to_resource?(center)
      center_coordinator.access_privileges.build(:role=>Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:center_coordinator][:text]),:resource=>center)
    end
    center_coordinator.password = center_coordinator.firstname.squeeze.gsub(" ","_")  if center_coordinator.firstname
    center_coordinator.password_confirmation = center_coordinator.firstname.squeeze.gsub(" ","_") if center_coordinator.firstname
    if not center_coordinator.save
      puts "Center cooridnator for #{center.name} has not been saved becuase of  #{center_coordinator.errors.messages}"
    end
  end


##### Importing Teacher #####
  workbook1 = RubyXL::Parser.parse("Teacher.xlsx")
  sheet1=workbook1["PersonalDetails"].get_table
  sheet1[:table].each do |row|
    teacher=Teacher.find_or_initialize_by_t_no(row["TraineeID"])
    if teacher.new_record?
      teacher.t_no = row["TraineeID"]
      teacher.state = Teacher::STATE_UNATTACHED.to_s
      user=User.find_or_initialize_by_email(row["teacher_email_address"])
      if user.new_record?
        user.firstname=row["name"]
        user.address="#{row['teacher_addressline1']}\n#{row['teacher_addressline2']}"
        user.mobile=row["teacher_phoneno_mobile"]
      end
    elsif
      user = User.find_by_id(teacher.user_id)
    end

    #teacher.access_privileges.build(:role=>Role.find_by_name("Teacher") ) #,:resource=>sector)
    #elsif not teacher.access_to_resource?(zone)
    #  teacher.access_privileges.build(:role=>Role.find_by_name("Teacher")) #,:resource=>sector)
    #end

    user.password= teacher.firstname.squeeze.gsub(" ","_")  if teacher.firstname
    user.password_confirmation = teacher.firstname.squeeze.gsub(" ","_") if teacher.firstname
    user.save
    if not user.save
      puts "Teacher #{teacher.firstname} has not been saved because of #{teacher.errors.messages}"
    end

    if not teacher.save
      puts "Teacher #{teacher.firstname} has not been saved because of #{teacher.errors.messages}"
    end

  end




