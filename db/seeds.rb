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
].each {|e| Venue.create(e) }