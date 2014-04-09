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
  validates :start_date, :presence => true
#  validates :end_date, :presence => true
  validates :center_id, :presence => true
  validates :proposer_id, :presence => true

  attr_accessible :name, :program_type_id, :start_date, :center_id, :end_date

  before_create :assign_dates!

  belongs_to :center
  belongs_to :program_type
  has_many :venue_schedules
  attr_accessible :venue_schedules, :venue_schedule_ids
  has_many :kit_schedules
  attr_accessible :kit_schedules, :kit_schedule_ids
  has_many :teacher_schedules
  attr_accessible :teacher_schedules, :teacher_schedule_ids
  has_many :teachers, :through => :teacher_schedules
  attr_accessible :teachers, :teacher_ids

  has_and_belongs_to_many :timings, :join_table => :programs_timings
  attr_accessible :timing_ids, :timings

  STATE_PROPOSED = :proposed
  STATE_ANNOUNCED = :announced
  STATE_REGISTRATION_OPEN = :registration_open
  STATE_CANCELLED = :cancelled
  STATE_IN_PROGRESS = :in_progress
  STATE_CONDUCTED = :conducted
  STATE_CLOSED = :closed

  PROCESSABLE_EVENTS = [
    :announce, :registration_open, :start, :finish, :close, :cancel
  ]

  # timing_ids = program.timing_ids.class == Array ? program.timing_ids : [program.timing_ids]
  # given a program, returns a relation with other non-overlapping program(s)
  scope :available, lambda { |program| Program.joins("JOIN programs_timings ON programs.id = programs_timings.program_id").where('(programs.start_date NOT BETWEEN ? AND ?) AND (programs.end_date NOT BETWEEN ? AND ?) AND NOT (programs.start_date <= ? AND programs.end_date >= ?) AND programs_timings.timing_id NOT IN (?) AND programs.id != ? ',
                                                                             program.start_date, program.end_date, program.start_date, program.end_date, program.start_date, program.end_date, program.timing_ids, program.id) }

  # given a program, returns a relation with other overlapping program(s)
  scope :overlapping, lambda { |program| Program.joins("JOIN programs_timings ON programs.id = programs_timings.program_id").where('(programs.start_date BETWEEN ? AND ?) OR (programs.end_date BETWEEN ? AND ?) OR  (programs.start_date <= ? AND programs.end_date >= ?) AND programs_timings.timing_id IN (?) AND programs.id != ? ',
                                                                               program.start_date, program.end_date, program.start_date, program.end_date, program.start_date, program.end_date, program.timing_ids, program.id) }


  def initialize(*args)
    super(*args)
  end

  state_machine :state, :initial => STATE_PROPOSED do
    after_transition any => STATE_ANNOUNCED do |program, transition|
      program.generate_program_id!
    end

    event :announce do
      transition STATE_PROPOSED => STATE_ANNOUNCED
    end

    event :registration_open do
      transition STATE_ANNOUNCED => STATE_REGISTRATION_OPEN
    end

    event :start do
      transition [STATE_ANNOUNCED, STATE_REGISTRATION_OPEN] => STATE_IN_PROGRESS
    end

    event :finish do
      transition [STATE_IN_PROGRESS] => STATE_CONDUCTED
    end

    event :close do
      transition STATE_CONDUCTED => STATE_CLOSED
    end

    event :cancel do
      transition [STATE_PROPOSED, STATE_ANNOUNCED, STATE_REGISTRATION_OPEN] => STATE_CANCELLED
    end

  end

  def friendly_name
    ("%s %s %s" % [self.center.name, self.start_date.strftime('%d-%m-%Y'), self.program_type.name]).parameterize
  end

  def is_announced?
    ! [STATE_PROPOSED.to_s, ''].include?(self.state.to_s)
  end

  def generate_program_id!
    self.announce_program_id = ("%s %s %d" % 
      [self.center.name, self.start_date.strftime('%B%Y'), self.id]
    ).parameterize
    self.save!
  end
  
  def proposer
    ::User.find(self.proposer_id)
  end

  def venue_connected?
    !self.venue_schedules.empty?
  end

  #def connect_venue(venue)
  #  self.venue_schedule_id = venue.id
  #  self.save!
  #end

  #def disconnect_venue(venue)
  #  self.venue_schedule_id = nil
  #  self.save!
  #end

  def kit_connected?
    !self.kit_schedules.empty?
  end

  #def connect_kit(kit)
  #  self.kit_schedule_id = kit.id
  #  self.save
  #end

  #def disconnect_kit(kit)
  #  self.kit_schedule_id = nil
  #  self.save!
  #end


  def blockable_venues
    # the list returned here is not a confirmed list, it is a tentative list which might fail validations later
    # TODO - writing the query for confirmed list is too db intensive for now, so skipping it
    Venue.joins("JOIN centers_venues ON venues.id = centers_venues.venue_id").where('centers_venues.center_id = ?', self.center_id)
  end

  def blockable_kits
    # the list returned here is not a confirmed list, it is a tentative list which might fail validations later
    # TODO - writing the query for confirmed list is too db intensive for now, so skipping it
    Kit.joins("JOIN centers_kits ON kits.id = centers_kits.kit_id").where('centers_kits.center_id = ?', self.center_id)
  end

  def assign_dates!
    self.end_date = self.start_date + self.program_type.no_of_days.to_i.days
  end

  def teachers_connected
    self.teachers.uniq.count
  end

  def minimum_teachers_connected?
    self.teachers_connected >= self.program_type.minimum_no_of_teacher
  end

  def ready_for_announcement?
    return false unless self.venue_connected?
    return false unless self.kit_connected?
    return false unless self.minimum_teachers_connected?

    true
  end
end
