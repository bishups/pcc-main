class VenueSchedule < ActiveRecord::Base
  # attr_accessible :title, :body
  attr_accessible :slot
  attr_accessible :start_date
  attr_accessible :end_date

  validates :start_date, :presence => true
  validates :end_date, :presence => true
  validates :slot, :presence => true
  validates :reserving_user_id, :presence => true

  # Overlap validation
  validates_with VenueScheduleValidator

  belongs_to :venue
  belongs_to :reserving_user, :class_name => User

end
