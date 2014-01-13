class Venue < ActiveRecord::Base
  # attr_accessible :title, :body
  attr_accessible :name
  attr_accessible :description
  attr_accessible :address
  attr_accessible :pin_code
  attr_accessible :capacity
  attr_accessible :seats
  attr_accessible :contact_name
  attr_accessible :contact_phone
  attr_accessible :contact_mobile
  attr_accessible :contact_email
  attr_accessible :contact_address
  attr_accessible :zone_id
  attr_accessible :center_id

  has_many :venue_schedules

  validates_presence_of :zone_id
  validates_presence_of :center_id
  validates_uniqueness_of :name, :scope => [:zone_id, :center_id]

end
