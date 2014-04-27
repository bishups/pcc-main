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
  include CommonFunctions

  # attr_accessible :title, :body
  attr_accessible :program_id, :program

  validates :blocked_by_user_id, :presence => true
  validates :program_id, :presence => true

  # Overlap validation
  validates_with VenueScheduleValidator
  #validates_uniqueness_of :program_id

  attr_accessor :blocked_for, :current_user
  #attr_accessible :blocked_for

  belongs_to :venue
  validates :venue_id, :presence => true
  attr_accessible :venue_id, :venue
  validates_uniqueness_of :program_id, :scope => "venue_id", :unless => :venue_schedule_cancelled?, :message => " is already associated with the Venue."


  belongs_to :blocked_by_user, :class_name => User
  belongs_to :program
  belongs_to :last_updated_by_user, :class_name => User
  attr_accessible :last_update, :last_updated_at

  attr_accessor :comment_category
  attr_accessible :comment_category

  has_many :timings, :through => :program

  #before_create :assign_details!
  #after_create :connect_program!

  # given a venue_schedule, returns a relation with other overlapping venue_schedule(s)
  scope :overlapping, lambda { |vs| joins(:program).merge(Program.overlapping(vs.program)).where('venue_schedules.id IS NOT ? AND venue_schedules.state NOT IN (?) AND venue_schedules.venue_id IS ?', vs.id, ::VenueSchedule::FINAL_STATES, vs.venue_id) }

  # given a venue_schedule, returns a relation with other non-overlapping venue_schedule(s)
  scope :available, lambda { |vs| joins(:program).merge(Program.available(vs.program)).where('venue_schedules.id IS NOT ? AND venue_schedules.state NOT IN (?) AND venue_schedules.venue_id IS ?', vs.id, ::VenueSchedule::FINAL_STATES, vs.venue_id) }

  STATE_UNKNOWN                   = "Unknown"
  STATE_BLOCK_REQUESTED           = "Block Requested"
  STATE_BLOCKED                   = "Blocked"
  STATE_APPROVAL_REQUESTED        = "Approval Requested"
  STATE_AUTHORIZED_FOR_PAYMENT    = "Authorized for Payment"
  STATE_PAYMENT_PENDING           = "Payment Pending"
  STATE_PAID                      = "Paid"
  STATE_ASSIGNED                  = "Assigned"
  STATE_IN_PROGRESS               = "In Progress"
  STATE_CONDUCTED                 = "Conducted"
  STATE_SECURITY_REFUNDED         = "Security Refunded"
  STATE_CLOSED                    = "Closed"
  STATE_CANCELLED                 = "Cancelled"
  STATE_UNAVAILABLE               = "Unavailable"

  # connected to program

  PAID_STATES = [STATE_PAID, STATE_ASSIGNED, STATE_IN_PROGRESS, STATE_CONDUCTED, STATE_SECURITY_REFUNDED, STATE_CLOSED]
  CONNECTED_STATES = (PAID_STATES + [STATE_BLOCK_REQUESTED, STATE_BLOCKED, STATE_APPROVAL_REQUESTED, STATE_AUTHORIZED_FOR_PAYMENT, STATE_PAYMENT_PENDING])
  # final states
  FINAL_STATES = [STATE_UNAVAILABLE, STATE_CANCELLED, STATE_CLOSED]

  EVENT_BLOCK_REQUEST     = "Block Request"
  EVENT_BLOCK             = "Block"
  EVENT_REJECT            = "Reject"
  EVENT_BLOCK_EXPIRED     = "Block Expired"
  EVENT_CANCEL            = "Cancel"
  EVENT_REQUEST_APPROVAL  = "Request Approval"
  EVENT_AUTHORIZE_FOR_PAYMENT = "Authorize for Payment"
  EVENT_REQUEST_PAYMENT   = "Request Payment"
  EVENT_PAID              = "Paid"
  EVENT_SECURITY_REFUNDED = "Security Refunded"
  EVENT_CLOSE             = "Close"

  PROCESSABLE_EVENTS = [
    EVENT_BLOCK, EVENT_REJECT, EVENT_REQUEST_APPROVAL, EVENT_AUTHORIZE_FOR_PAYMENT, EVENT_REQUEST_PAYMENT, EVENT_PAID, EVENT_CANCEL, EVENT_CLOSE
  ]

  EVENTS_WITH_COMMENTS = [EVENT_REJECT, EVENT_CANCEL, EVENT_SECURITY_REFUNDED]
  EVENTS_WITH_FEEDBACK = [EVENT_CLOSE]

  NOTIFICATIONS = [EVENT_BLOCK_EXPIRED]

  def initialize(*args)
    super(*args)
  end

  #def setup_details!
  #  assign_details!
  #end

  state_machine :state, :initial => STATE_UNKNOWN do

    event EVENT_BLOCK_REQUEST do
      transition STATE_UNKNOWN => STATE_BLOCK_REQUESTED, :if => lambda {|t| t.can_create?}
    end
    before_transition STATE_UNKNOWN => STATE_BLOCK_REQUESTED, :do => :can_block?

    event EVENT_REJECT do
      transition STATE_BLOCK_REQUESTED => STATE_UNAVAILABLE, :if => lambda {|t| t.is_venue_coordinator? }
    end
    before_transition STATE_BLOCK_REQUESTED => STATE_UNAVAILABLE, :do => :is_venue_coordinator?

    event EVENT_BLOCK do
      transition STATE_BLOCK_REQUESTED => STATE_BLOCKED
    end
    before_transition any => STATE_BLOCKED, :do => :before_block
    after_transition any => STATE_BLOCKED, :do => :after_block

    event EVENT_CANCEL do
      transition STATE_BLOCK_REQUESTED => STATE_CANCELLED, :if => lambda {|t| t.is_center_scheduler? }
    end
    before_transition STATE_BLOCK_REQUESTED => STATE_UNAVAILABLE, :do => :is_center_scheduler?

    event ::Program::DROPPED do
      transition [STATE_BLOCK_REQUESTED, STATE_BLOCKED, STATE_APPROVAL_REQUESTED] => STATE_CANCELLED
    end

    event ::Program::CANCELLED do
      transition [STATE_PAID, STATE_ASSIGNED] => STATE_CANCELLED
    end

    event EVENT_REQUEST_APPROVAL do
      transition STATE_BLOCKED => STATE_APPROVAL_REQUESTED, :if => lambda {|t| t.is_center_scheduler? }
    end
    before_transition any => STATE_APPROVAL_REQUESTED, :do => :can_request_approval?


    event EVENT_AUTHORIZE_FOR_PAYMENT do
      transition STATE_APPROVAL_REQUESTED => STATE_AUTHORIZED_FOR_PAYMENT, :if => lambda {|t| t.is_sector_coordinator? }
    end
    before_transition STATE_APPROVAL_REQUESTED => STATE_AUTHORIZED_FOR_PAYMENT, :do => :is_sector_coordinator?
    after_transition any => STATE_AUTHORIZED_FOR_PAYMENT, :do => :on_authorization_for_payment?

    event EVENT_REQUEST_PAYMENT do
      transition STATE_AUTHORIZED_FOR_PAYMENT => STATE_PAYMENT_PENDING, :if => lambda {|vs| !vs.venue_free?}
    end
    before_transition STATE_AUTHORIZED_FOR_PAYMENT => STATE_PAYMENT_PENDING do |vs, transition|
        return !vs.venue_free?
    end

    event EVENT_BLOCK_EXPIRED do
      transition [STATE_BLOCKED, STATE_APPROVAL_REQUESTED, STATE_AUTHORIZED_FOR_PAYMENT, STATE_PAYMENT_PENDING] => STATE_BLOCK_REQUESTED
    end

    event EVENT_PAID do
      transition STATE_AUTHORIZED_FOR_PAYMENT => STATE_PAID, :if => lambda {|vs| vs.venue_free?}
      transition STATE_PAYMENT_PENDING => STATE_PAID, :if => lambda {|vs| !vs.venue_free? && vs.is_pcc_accounts? }
    end
    before_transition STATE_AUTHORIZED_FOR_PAYMENT => STATE_PAID, :do => :venue_free?
    before_transition STATE_PAYMENT_PENDING => STATE_PAID do |vs, transition|
        return !vs.venue_free? && vs.is_pcc_accounts?
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

    event EVENT_SECURITY_REFUNDED do
      transition STATE_CONDUCTED => STATE_SECURITY_REFUNDED, :if => lambda {|vs| !vs.venue_free? && vs.is_venue_coordinator? }
    end
    before_transition STATE_CONDUCTED => STATE_SECURITY_REFUNDED do |vs, transition|
      return !vs.venue_free? && vs.is_venue_coordinator?
    end

    event EVENT_CLOSE do
      transition STATE_CONDUCTED => STATE_CLOSED, :if => lambda {|vs| vs.venue_free? && vs.is_center_coordinator? }
      transition STATE_SECURITY_REFUNDED => STATE_CLOSED, :if => lambda {|vs| !vs.venue_free? && vs.is_center_coordinator? }
    end
    before_transition STATE_CONDUCTED => STATE_CLOSED do |vs, transition|
      return vs.venue_free? && vs.is_center_coordinator?
    end
    before_transition STATE_SECURITY_REFUNDED => STATE_CLOSED do |vs, transition|
      return !vs.venue_free? && vs.is_center_coordinator?
    end

    # check for comments, before any transition
    before_transition any => any do |object, transition|
      if EVENTS_WITH_COMMENTS.include?(transition.event) && !object.has_comments?
        return false
      end
      if EVENTS_WITH_FEEDBACK.include?(transition.event) && !object.has_feedback?
        return false
      end
    end

    after_transition any => any do |object, transition|
      object.store_last_update!(object.current_user, transition.from, transition.to, transition.event)
      object.notify(transition.from, transition.to, transition.event, object.program.center_id)
    end

  end

  def can_block?
    unless self.can_create?
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    end
    true
  end

  def reloaded?
    self.reload
    return true
  rescue ActiveRecord::RecordNotFound
    # TODO - check if to log any error
    return false
  end

  def venue_schedule_cancelled?
    VenueSchedule.where('program_id IS ? AND venue_id IS ? AND state NOT IN (?)', self.program_id, self.venue_id, FINAL_STATES).count == 0
  end

  def trigger_block_expire
    return if !self.reloaded?
    if [STATE_BLOCKED, STATE_APPROVAL_REQUESTED, STATE_AUTHORIZED_FOR_PAYMENT, STATE_PAYMENT_PENDING].include?(self.state)
      self.send(EVENT_BLOCK_EXPIRED)
      self.save if self.errors.empty?
    end
  end

  def before_block
    return false unless self.is_venue_coordinator?
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
      self.send(::Program::ANNOUNCED)
    end
  end

  def venue_free?
    self.venue.free?
  end

  def is_connected?
    CONNECTED_STATES.include?(self.state)
  end

  def is_active?
    return false if FINAL_STATES.include?(self.state)
    return false if !self.program.is_active?
    true
  end

  def on_authorization_for_payment?
    if self.errors.empty?
      #self.save
      event = self.venue_free? ? EVENT_PAID : EVENT_REQUEST_PAYMENT
      self.send(event)
    end
  end

  def can_request_approval?
    return false unless self.is_center_scheduler?

    if approval_requested_for_other_venue?
      return false unless self.has_comments?
    end

    # approve if program already announced
    return true if self.program.is_announced?

    # If a proposed program is not announced, and other resources are available for announcement
    if self.program.in_final_state?
      self.errors[:base] << "Program is already closed. Cannot request approval."
      return false
    end
    if !self.program.kit_connected?
      self.errors[:base] << "Kit is not added to the program. Please add a kit and try again."
      return false
    end

    if !self.program.minimum_teachers_connected?
      self.errors[:base] << "Minimum number of teachers are not added to the program. Please add teacher(s) and try again."
      return false
    end

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
    !([STATE_BLOCK_REQUESTED, STATE_BLOCKED, STATE_UNAVAILABLE, STATE_CANCELLED].include?(self.state))
  end

  # has the payment been approved for the venue?
  def approved?
    !([STATE_BLOCK_REQUESTED, STATE_BLOCKED, STATE_APPROVAL_REQUESTED, STATE_UNAVAILABLE, STATE_CANCELLED].include?(self.state))
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
      self.comments = event
      self.send(event)
      # also call save on the model
      # TODO - check if this is really needed
      self.save if self.errors.empty?
    else
      # TODO - IMPORTANT - log that we are ignore the event and what state are we in presently
    end
  end

  def is_center_coordinator?
    if self.current_user.is? :center_coordinator, :center_id => self.program.center_id
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      false
    end
    true
  end

  def is_venue_coordinator?
    if self.current_user.is? :venue_coordinator, :center_id => self.program.center_id
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      false
    end
    true
  end

  def is_sector_coordinator?
    if self.current_user.is? :sector_coordinator, :center_id => self.program.center_id
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      false
    end
    true
  end

  def is_center_scheduler?
    if self.current_user.is? :center_scheduler, :center_id => self.program.center_id
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      false
    end
    true
  end

  def is_pcc_accounts?
    if self.current_user.is? :pcc_accounts, :center_id => self.program.center_id
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      false
    end
    true
  end

  def can_create?(center_ids = self.program.center_id)
    return true if self.current_user.is? :center_scheduler, :for => :any, :center_id => center_ids
    return false
  end

  def can_update?
    return true if self.current_user.is? :center_scheduler, :center_id => self.program.center_id
    return true if self.current_user.is? :venue_coordinator, :center_id => self.program.center_id
    return true if self.current_user.is? :pcc_accounts, :center_id => self.program.center_id
    return false
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
