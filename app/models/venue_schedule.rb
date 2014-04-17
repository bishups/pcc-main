# == Schema Information
#
# Table name: venue_schedules
#
#  id                :integer          not null, primary key
#  venue_id          :integer
#  reserving_user_id :integer
#  slot              :string(255)
#  start_date        :datetime
#  end_date          :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  program_id        :integer
#  state             :string(255)
#

class VenueSchedule < ActiveRecord::Base
  # attr_accessible :title, :body
  attr_accessible :program_id, :program

  validates :blocked_by_user_id, :presence => true
  validates :program_id, :presence => true

  # Overlap validation
  validates_with VenueScheduleValidator
  #validates_uniqueness_of :program_id

  attr_accessor :blocked_for
  #attr_accessible :blocked_for

  belongs_to :venue
  validates :venue_id, :presence => true
  attr_accessible :venue_id
  validates_uniqueness_of :program_id, :scope => "venue_id"

  belongs_to :blocked_by_user, :class_name => User
  belongs_to :program

  has_many :timings, :through => :program

  #before_create :assign_details!
  #after_create :connect_program!

  # given a venue_schedule, returns a relation with other overlapping venue_schedule(s)
  scope :overlapping, lambda { |vs| joins(:program).merge(Program.overlapping(vs.program)).where('venue_schedules.id IS NOT ? AND venue_schedules.state != ?', vs.id, ::VenueSchedule::STATE_CANCELLED) }

  # given a venue_schedule, returns a relation with other non-overlapping venue_schedule(s)
  scope :available, lambda { |vs| joins(:program).merge(Program.available(vs.program)).where('venue_schedules.id IS NOT ? AND venue_schedules.state != ?', vs.id, ::VenueSchedule::STATE_CANCELLED) }


  STATE_BLOCK_REQUESTED           = "Block Requested"
  STATE_DROPPED                   = "Dropped"
  STATE_BLOCKED                   = "Blocked"
  STATE_APPROVAL_REQUESTED        = "Approval Requested"
  STATE_AUTHORIZED_FOR_PAYMENT    = "Authorized for Payment"
  STATE_PAYMENT_PENDING           = "Payment Pending"
  STATE_PAID                      = "Paid"
  STATE_ASSIGNED                  = "Assigned"
  STATE_IN_PROGRESS               = "In Progress"
  STATE_CONDUCTED                 = "Conducted"
  STATE_CLOSED                    = "Closed"
  STATE_CANCELLED                 = "Cancelled"

  # connected to program

  PAID_STATES = [STATE_PAID, STATE_ASSIGNED, STATE_IN_PROGRESS, STATE_CONDUCTED, STATE_CLOSED]
  CONNECTED_STATES = (PAID_STATES + [STATE_BLOCK_REQUESTED, STATE_BLOCKED, STATE_APPROVAL_REQUESTED, STATE_AUTHORIZED_FOR_PAYMENT, STATE_PAYMENT_PENDING])
  # final states
  FINAL_STATES = [STATE_DROPPED, STATE_CANCELLED, STATE_CLOSED]

  EVENT_BLOCK             = "Block"
  EVENT_BLOCK_EXPIRED     = "Block Expired"
  EVENT_CANCEL            = "Cancel"
  EVENT_REQUEST_APPROVAL  = "Request Approval"
  EVENT_AUTHORIZE_FOR_PAYMENT = "Authorize for Payment"
  EVENT_REQUEST_PAYMENT   = "Request Payment"
  EVENT_PAID              = "Paid"
  EVENT_CLOSE             = "Close"

  PROCESSABLE_EVENTS = [
    EVENT_BLOCK, EVENT_REQUEST_APPROVAL, EVENT_AUTHORIZE_FOR_PAYMENT, EVENT_REQUEST_PAYMENT, EVENT_PAID, EVENT_CANCEL, EVENT_CLOSE
  ]

  def initialize(*args)
    super(*args)
  end

  #def setup_details!
  #  assign_details!
  #end

  state_machine :state, :initial => STATE_BLOCK_REQUESTED do

    event EVENT_BLOCK do
      transition STATE_BLOCK_REQUESTED => STATE_BLOCKED
    end
    before_transition any => STATE_BLOCKED, :do => :before_block
    after_transition any => STATE_BLOCKED, :do => :after_block

    event EVENT_CANCEL do
      transition STATE_BLOCK_REQUESTED => STATE_DROPPED
    end

    event ::Program::DROPPED do
      transition STATE_BLOCK_REQUESTED => STATE_DROPPED
      transition [STATE_BLOCKED, STATE_APPROVAL_REQUESTED] => STATE_CANCELLED
    end

    event ::Program::CANCELLED do
      transition [STATE_PAID, STATE_ASSIGNED] => STATE_CANCELLED
    end

    event EVENT_REQUEST_APPROVAL do
      transition STATE_BLOCKED => STATE_APPROVAL_REQUESTED
    end
    before_transition any => STATE_APPROVAL_REQUESTED, :do => :can_request_approval?


    event EVENT_AUTHORIZE_FOR_PAYMENT do
      transition STATE_APPROVAL_REQUESTED => STATE_AUTHORIZED_FOR_PAYMENT
    end
    after_transition any => STATE_AUTHORIZED_FOR_PAYMENT, :do => :on_authorization_for_payment?

    event EVENT_REQUEST_PAYMENT do
      transition STATE_AUTHORIZED_FOR_PAYMENT => STATE_PAYMENT_PENDING, :if => lambda {|vs| !vs.venue_free?}
    end

    event EVENT_BLOCK_EXPIRED do
      transition [STATE_BLOCKED, STATE_APPROVAL_REQUESTED, STATE_AUTHORIZED_FOR_PAYMENT, STATE_PAYMENT_PENDING] => STATE_BLOCK_REQUESTED
    end

    event EVENT_PAID do
      transition STATE_AUTHORIZED_FOR_PAYMENT => STATE_PAID, :if => lambda {|vs| vs.venue_free?}
      transition STATE_PAYMENT_PENDING => STATE_PAID, :if => lambda {|vs| !vs.venue_free?}
    end
    after_transition any => STATE_PAID, :do => :on_paid

    event ::Program::ANNOUNCED do
      transition STATE_PAID => STATE_ASSIGNED
    end

    event ::Program::STARTED do
      transition STATE_ASSIGNED => STATE_IN_PROGRESS
    end

    event ::Program::FINISHED do
      transition STATE_IN_PROGRESS => STATE_CONDUCTED
    end

    event EVENT_CLOSE do
      transition STATE_CONDUCTED => STATE_CLOSED
    end

  end

  def trigger_block_expire
    if [STATE_BLOCKED, STATE_APPROVAL_REQUESTED, STATE_AUTHORIZED_FOR_PAYMENT, STATE_PAYMENT_PENDING].include?(self.state)
      self.send(EVENT_BLOCK_EXPIRED)
      self.save if self.errors.empty?
    end
  end

  def before_block
    blocked_for = self.blocked_for ? self.blocked_for.to_i : 0
    if !blocked_for.between?(1,90)
      self.errors[:blocked_for] << "Venue can be blocked from 1 to 90 days."
      false
    end
  end

  def after_block
    self.delay(:run_at => self.blocked_for.to_i.days.from_now).trigger_block_expire
    true
  end

  def on_paid
    if self.program.is_announced?
      self.fire_state_event(::Program::ANNOUNCED)
    end
  end

  def venue_free?
    self.venue.free?
  end

  def is_connected?
    CONNECTED_STATES.include?(self.state)
  end


  def on_authorization_for_payment?
    if self.errors.empty?
      #self.save
      event = self.venue_free? ? EVENT_PAID : EVENT_REQUEST_PAYMENT
      self.send(event)
    end
  end

  def can_request_approval?
    if approval_requested_for_other_venue?
      # TODO - make sure that the comments have been entered
    end

    # approve if program already announced
    return true if self.program.is_announced?

    # If a proposed program is not announced, and other resources are available for announcement
    return false if self.program.in_final_state?
    return false unless self.program.kit_connected?
    return false unless self.program.minimum_teachers_connected?

    true
  end

  def approval_requested_for_other_venue?
    self.program.venue_schedules.each { |vs|
      return true if vs.approval_requested?
    }
    false
  end

  # have we requested the approval for the venue?
  def approval_requested?
    !([STATE_BLOCK_REQUESTED, STATE_BLOCKED, STATE_DROPPED, STATE_CANCELLED].include?(self.state))
  end

  # has the payment been approved for the venue?
  def approved?
    !([STATE_BLOCK_REQUESTED, STATE_BLOCKED, STATE_APPROVAL_REQUESTED, STATE_DROPPED, STATE_CANCELLED].include?(self.state))
  end

  def on_program_event(event)
    valid_states = {
        ::Program::CANCELLED => [STATE_PAID, STATE_ASSIGNED],
        ::Program::DROPPED => [STATE_BLOCK_REQUESTED, STATE_BLOCKED, STATE_APPROVAL_REQUESTED],
        ::Program::ANNOUNCED => [STATE_PAID],
        ::Program::STARTED => [STATE_ASSIGNED],
        ::Program::FINISHED => [STATE_IN_PROGRESS],

    }

    # verify when all the events can come
    if valid_states[event].include?(self.state)
      self.send(event)
      # also call save on the model
      # TODO - check if this is really needed
      self.save if self.errors.empty?
    else
      # TODO - IMPORTANT - log that we are ignore the event and what state are we in presently
    end
  end

  private

  #def assign_details!
  #  program = ::Program.where(:id => self.program_id).first()
  #  return if program.nil?

    #self.slot = program.slot
    #self.start_date = program.start_date
    #self.end_date = program.end_date
  #end

  #def connect_program!
  #  self.program.connect_venue(self)
  #end

end
