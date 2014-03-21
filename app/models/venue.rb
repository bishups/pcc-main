# == Schema Information
#
# Table name: venues
#
#  id              :integer          not null, primary key
#  center_id       :integer
#  zone_id         :integer
#  name            :string(255)
#  description     :text
#  address         :text
#  pin_code        :string(255)
#  capacity        :string(255)
#  seats           :integer
#  state           :string(255)
#  contact_name    :string(255)
#  contact_email   :string(255)
#  contact_phone   :string(255)
#  contact_mobile  :string(255)
#  contact_address :text
#  commercial      :boolean
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

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

  belongs_to :center
  has_many :venue_schedules

  validates_presence_of :zone_id
  validates_presence_of :center_id
  validates_uniqueness_of :name, :scope => [:zone_id, :center_id]

  def current_schedule
    self.venue_schedules.where('start_date < ? AND end_date > ?', Time.now, Time.now).first()
  end

  def current_state
    vs = current_schedule
    vs ? vs.state : 'Unknown'
  end

end
