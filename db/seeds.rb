# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

[
    {
        :zone_id => 1,
        :center_id => 1,
        :name => 'Sample Venue 1',
        :description => 'Sample Venue description',
        :pin_code => '555555',
        :address => 'Sample Venue address',
        :capacity => ::Ontology::Venue::CAPACITY_MEDIUM,
        :seats => 200,
        :contact_name => 'Contact Name1',
        :contact_phone => '11111111',
        :contact_mobile => '989898989',
        :contact_email => 's@s.com',
        :contact_address => 'sssss'
    }
].each { |e| Venue.create(e) }

Role.init_roles!

[
    {"OTN1" => {"Banglore" => ["Banglore-Koramangala", "Banglore-Indranagar"]}},
    {"TN" => {"Nagercoil" => ["Nagercoil", "Madurai"]}},
    {"Chennai" => {"Chennai-East" => ["Chennai-TNagar", "Chennai-Adayar"]}},
].each do |zone|
  sector_obj = nil
  zone.values.each do |sector|
    centers = sector.values.flatten.collect { |c| Center.new(:name => c) }
    sector_obj = Sector.new(:name => sector.keys.first, :centers => centers)
  end
  zone = Zone.new(:name => zone.keys.first, :sectors => [sector_obj])
  zone.save
  puts zone.errors.messages
end

[
    {
        :email => "pcc-admin@isha.org",
        :firstname => "Admin",
        :password => "isha-123"
    },
    {
        :email => "pcc-organiser-banglore@isha.org",
        :firstname => "Organiser Banglore",
        :password => "isha-123",
        :access_privilege_names => [ {:role_name => "Center Organiser", :center_name => "Banglore-Koramangala"},
                                {:role_name => "Center Organiser", :center_name => "Banglore-Indranagar"}
                               ]
    },
    {
        :email => "pcc-treasurer-banglore@isha.org",
        :firstname => ["Treasurer Banglore"],
        :password => "isha-123",
        :access_privilege_names => [ {:role_name => "Center Treasurer", :center_name => "Banglore-Koramangala"},
                                {:role_name => "Center Treasurer", :center_name => "Banglore-Indranagar"}
        ]
    },
    {
        :email => "pcc-organiser-chennai@isha.org",
        :firstname => "Organiser Chennai",
        :password => "isha-123",
        :access_privilege_names => [ {:role_name => "Center Organiser", :center_name => "Chennai-TNagar"},
                                {:role_name => "Center Organiser", :center_name => "Chennai-Adayar"}
        ]
    },
    {
        :email => "pcc-treasuruer-organiser@isha.org",
        :firstname => "Treasuruer Hyderabad",
        :password => "isha-123",
        :access_privilege_names => [ {:role_name => "Center Treasurer", :center_name => "Chennai-TNagar"}
                                 ]
    }
].each do |u|
  user=User.new(u)
  user.skip_confirmation!
  user.save
  puts user.errors.messages
end
