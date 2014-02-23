class Program < ActiveRecord::Base
  validates :slot, :presence => true
  validates :start_date, :presence => true
  #validates :end_date, :presence => true
  validates :center_id, :presence => true
  validates :proposer_id, :presence => true

  attr_accessible :name
  attr_accessible :program_type_id
  attr_accessible :start_date
  attr_accessible :center_id
  attr_accessible :slot

  before_create :assign_dates!

  belongs_to :center
  belongs_to :venue_schedule
  belongs_to :program_type

  def proposer
    ::User.find(self.proposer_id)
  end

  def venue_connected?
    self.venue_schedule_id != nil
  end

  def connect_venue(venue)
    self.venue_schedule_id = venue.id
    self.save!
  end

  def disconnect_venue(venue)
    self.venue_schedule_id = nil
    self.save!
  end

  private

  def assign_dates!
    self.end_date = self.start_date + self.program_type.no_of_days.to_i.days
  end
end
