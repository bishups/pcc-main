# == Schema Information
#
# Table name: programs
#
#  id                  :integer          not null, primary key
#  name                :string(255)
#  description         :text
#  center_id           :string(255)
#  program_type_id     :integer
#  proposer_id         :integer
#  manager_id          :integer
#  state               :string(255)
#  start_date          :datetime
#  end_date            :datetime
#  slot                :string(255)
#  announce_program_id :string(255)
#  venue_schedule_id   :integer
#  kit_schedule_id     :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class Program < ActiveRecord::Base
  validates :slot, :presence => true
  validates :start_date, :presence => true
#  validates :end_date, :presence => true
  validates :center_id, :presence => true
  validates :proposer_id, :presence => true

  attr_accessible :name
  attr_accessible :program_type_id
  attr_accessible :start_date
  attr_accessible :center_id
  attr_accessible :slot
  attr_accessible :end_date

  before_create :assign_dates!

  belongs_to :center
  belongs_to :venue_schedule
  belongs_to :program_type
  belongs_to :kit_schedule
  has_many :program_teacher_schedules
  
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

  def kit_connected?
    self.kit_schedule_id != nil
  end

  def connect_kit(kit)
    self.kit_schedule_id = kit.id
    self.save
  end

  def disconnect_kit(kit)
    self.kit_schedule_id = nil
    self.save!
  end  

  def assign_dates!
    self.end_date = self.start_date + self.program_type.no_of_days.to_i.days
  end

  def minimum_teachers_connected?
    self.program_teacher_schedules.count >= self.program_type.minimum_no_of_teacher
  end

  def ready_for_announcement?
    return false unless self.venue_connected?
    return false unless self.kit_connected?
    return false unless self.minimum_teachers_connected?
  end
end
