# == Schema Information
#
# Table name: venue_schedules
#
#  id                      :integer          not null, primary key
#  venue_id                :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  program_id              :integer
#  state                   :string(255)
#  blocked_by_user_id      :integer
#  last_updated_by_user_id :integer
#  comments                :text
#  feedback                :text
#  last_update             :string(255)
#  last_updated_at         :datetime
#  payment_amount          :integer          default(0)
#

class VenueSchedule < ActiveRecord::Base
  include CommonFunctions

  # attr_accessible :title, :body
  attr_accessible :program_id, :program

  validates :blocked_by_user_id, :presence => true
  validates :program_id, :presence => true

  # Overlap validation
  validates_with VenueScheduleValidator, :on => :create
  #validates_uniqueness_of :program_id

  attr_accessor :block_expiry_date, :current_user
  #attr_accessible :blocked_for

  belongs_to :venue
  validates :venue_id, :presence => true
  attr_accessible :venue_id, :venue
  validates_uniqueness_of :program_id, :on => :create, :scope => "venue_id", :unless => :venue_schedule_cancelled?, :message => " is already associated with the Venue."
  validates :payment_amount, :length => {:maximum => 7},:numericality => {:only_integer => true }, :if =>  Proc.new { |vs| vs.venue.commercial? }

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
  scope :overlapping, lambda { |vs| joins(:program).merge(Program.overlapping(vs.program)).where('(venue_schedules.id != ? OR ? IS NULL) AND venue_schedules.state NOT IN (?) AND venue_schedules.venue_id = ? ', vs.id, vs.id, ::VenueSchedule::FINAL_STATES, vs.venue_id) }

  # given a venue and program, returns a relation containing all overlapping venue_schedule(s) for that venue (including the program itself - if present)
  scope :all_overlapping, lambda { |venue, program| joins(:program).merge(Program.all_overlapping(program)).where('venue_schedules.state NOT IN (?) AND venue_schedules.venue_id = ? ', ::VenueSchedule::FINAL_STATES, venue.id) }

  # given a venue_schedule, returns a relation with other non-overlapping venue_schedule(s)
  scope :available, lambda { |vs| joins(:program).merge(Program.available(vs.program)).where('(venue_schedules.id != ? OR ? IS NULL) AND venue_schedules.state NOT IN (?) AND venue_schedules.venue_id = ? ', vs.id, vs.id, ::VenueSchedule::FINAL_STATES, vs.venue_id) }

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
  STATE_EXPIRED                   = "Expired"
  STATE_AVAILABLE_EXPIRED         = "Available (Expired)"

  # connected to program

  PAID_STATES = [STATE_PAID, STATE_ASSIGNED, STATE_IN_PROGRESS, STATE_CONDUCTED, STATE_SECURITY_REFUNDED, STATE_CLOSED]
  CONNECTED_STATES = (PAID_STATES + [STATE_BLOCK_REQUESTED, STATE_BLOCKED, STATE_APPROVAL_REQUESTED, STATE_AUTHORIZED_FOR_PAYMENT, STATE_PAYMENT_PENDING])
  BLOCKED_STATES = (CONNECTED_STATES - [STATE_BLOCK_REQUESTED])
  # final states
  FINAL_STATES = [STATE_UNAVAILABLE, STATE_CANCELLED, STATE_CLOSED, STATE_EXPIRED, STATE_AVAILABLE_EXPIRED]


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
      transition STATE_BLOCK_REQUESTED => STATE_BLOCKED, :if => lambda {|t| t.is_venue_coordinator? }
    end
    before_transition any => STATE_BLOCKED, :do => :before_block
    after_transition any => STATE_BLOCKED, :do => :after_block

    event EVENT_CANCEL do
      transition STATE_BLOCK_REQUESTED => STATE_CANCELLED, :if => lambda {|t| t.is_center_scheduler? }
      transition STATE_BLOCKED => STATE_CANCELLED, :if => lambda {|t| t.is_center_scheduler? }
      transition STATE_APPROVAL_REQUESTED => STATE_CANCELLED, :if => lambda {|t| t.is_sector_coordinator? }
    end
    before_transition STATE_BLOCK_REQUESTED => STATE_CANCELLED, :do => :is_center_scheduler?
    before_transition STATE_BLOCKED => STATE_CANCELLED, :do => :can_cancel_block?
    before_transition STATE_APPROVAL_REQUESTED => STATE_CANCELLED, :do => :can_cancel_approval_request?

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
    before_transition STATE_APPROVAL_REQUESTED => STATE_AUTHORIZED_FOR_PAYMENT, :do => :can_authorize_for_payment?
    after_transition any => STATE_AUTHORIZED_FOR_PAYMENT, :do => :on_authorization_for_payment?

    event EVENT_REQUEST_PAYMENT do
      transition STATE_AUTHORIZED_FOR_PAYMENT => STATE_PAYMENT_PENDING, :if => lambda {|vs| !vs.venue_free?}
    end
    before_transition STATE_AUTHORIZED_FOR_PAYMENT => STATE_PAYMENT_PENDING do |vs, transition|
        !vs.venue_free?
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
        !vs.venue_free? && vs.is_pcc_accounts?
    end
    after_transition any => STATE_PAID, :do => :on_paid

    event ::Program::ANNOUNCED do
      transition STATE_PAID => STATE_ASSIGNED
    end
    after_transition STATE_PAID => STATE_ASSIGNED, :do => :on_assigned

    event ::Program::STARTED do
      transition STATE_ASSIGNED => STATE_IN_PROGRESS
    end

    event ::Program::FINISHED do
      transition STATE_IN_PROGRESS => STATE_CONDUCTED
      transition (BLOCKED_STATES - PAID_STATES) => STATE_AVAILABLE_EXPIRED
      transition STATE_BLOCK_REQUESTED => STATE_EXPIRED
    end

    event EVENT_SECURITY_REFUNDED do
      transition STATE_CONDUCTED => STATE_SECURITY_REFUNDED, :if => lambda {|vs| !vs.venue_free? && vs.is_venue_coordinator? }
    end
    before_transition STATE_CONDUCTED => STATE_SECURITY_REFUNDED do |vs, transition|
      !vs.venue_free? && vs.is_venue_coordinator?
    end

    event EVENT_CLOSE do
      transition STATE_CONDUCTED => STATE_CLOSED, :if => lambda {|vs| vs.venue_free? && vs.is_center_coordinator? }
      transition STATE_SECURITY_REFUNDED => STATE_CLOSED, :if => lambda {|vs| !vs.venue_free? && vs.is_center_coordinator? }
    end
    before_transition STATE_CONDUCTED => STATE_CLOSED do |vs, transition|
      vs.venue_free? && vs.is_center_coordinator?
    end
    before_transition STATE_SECURITY_REFUNDED => STATE_CLOSED do |vs, transition|
      !vs.venue_free? && vs.is_center_coordinator?
    end

    # check for comments, before any transition
    before_transition any => any do |object, transition|
      # Don't return here, else LocalJumpError will occur
      if EVENTS_WITH_COMMENTS.include?(transition.event) && !object.has_comments?
        false
      elsif EVENTS_WITH_FEEDBACK.include?(transition.event) && !object.has_feedback?
        false
      else
        true
      end
    end

    after_transition any => any do |object, transition|
      object.store_last_update!(object.current_user, transition.from, transition.to, transition.event)
      object.notify(transition.from, transition.to, transition.event, object.program.center)
    end

  end

  def can_cancel_block?
    return false unless self.is_center_scheduler?
    if self.program.no_of_venues_blocked <= 1
      self.errors[:base] << "Cannot remove the only blocked venue. Please block another venue and try again."
      return false
    end
    return true
  end

  def can_cancel_approval_request?
    return false unless self.is_sector_coordinator?
    if self.program.no_of_venues_blocked <= 1
      self.errors[:base] << "Cannot remove the only blocked venue. Please block another venue and try again."
      return false
    end
    return true
  end


  def can_block?
    return true if self.can_create?
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def reloaded?
    self.reload
    return true
  rescue ActiveRecord::RecordNotFound
    # TODO - check if to log any error
    return false
  end

  def venue_schedule_cancelled?
    VenueSchedule.where('program_id = ? AND venue_id = ? AND state NOT IN (?)', self.program_id, self.venue_id, FINAL_STATES).count == 0
  end

  def trigger_block_expire
    return if !self.reloaded?
    if [STATE_BLOCKED, STATE_APPROVAL_REQUESTED, STATE_AUTHORIZED_FOR_PAYMENT, STATE_PAYMENT_PENDING].include?(self.state)
      if self.program.end_date > Time.zone.now
        self.send(EVENT_BLOCK_EXPIRED)
        self.save if self.errors.empty?
      end
    end
  end

  def before_block
    return false unless self.is_venue_coordinator?

    if self.block_expiry_date.nil? || self.block_expiry_date.blank?
      self.errors[:block_expiry_date] << " cannot be blank."
      return false
    end

    expiry_date = Time.zone.parse(self.block_expiry_date) + 1.day - 1.minute
    self.block_expiry_date = expiry_date

    current_date = Time.zone.now
    days = (expiry_date.to_date - current_date.to_date).to_i

    unless days.between?(1,90)
      self.errors[:block_expiry_date] << " can be between 1 to 90 days."
      return false
    end

    if self.block_expiry_date > self.program.end_date
      self.errors[:block_expiry_date] << " cannot be beyond program close date."
      return false
    end

    return true
  end

  def after_block
    self.delay(:run_at => self.block_expiry_date).trigger_block_expire
    # They have to manually opt for permission, even if the program has started
    #self.send(EVENT_REQUEST_APPROVAL) if self.program.is_announced? && self.program.is_active?
    return true
  end

  def on_paid
    self.send(::Program::ANNOUNCED) if self.program.is_announced? && self.program.is_active?
  end

  def on_assigned
    self.send(::Program::STARTED) if self.program.in_progress?
  end

  def venue_free?
    self.venue.free?
  end

  def is_connected?
    CONNECTED_STATES.include?(self.state)
  end

  def is_active?
    return false if FINAL_STATES.include?(self.state)
    # EVEN if program is not active, we not mark venue as inactive, unless it is specifically marked so.
    #return false unless self.program.is_active?
    return true
  end

  def can_authorize_for_payment?
    return false unless self.is_sector_coordinator?
    if self.payment_amount.nil? || self.payment_amount < 0
      self.errors[:payment_amount] << " cannot be blank, or negative value."
      return false
    end
  end

  def on_authorization_for_payment?
    event = self.venue_free? ? EVENT_PAID : EVENT_REQUEST_PAYMENT
    self.send(event) if self.program.is_active?
  end

  def can_request_approval?
    return false unless self.is_center_scheduler?

    if approval_requested_for_other_venue?
      return false unless self.has_comments?
    end

    # approve if program already announced
    return true if self.program.is_announced? && self.program.is_active?

    # If a proposed program is not announced, and other resources are available for announcement
    unless self.program.is_active?
      self.errors[:base] << "Program is already closed. Cannot request approval."
      return false
    end
    if self.program.no_of_kits_connected <= 0
      self.errors[:base] << "Kit is not added to the program. Please add a kit and try again."
      return false
    end

    unless self.program.minimum_teachers_connected?
      self.errors[:base] << "Minimum number of teachers are not added to the program. Please add teacher(s) and try again."
      return false
    end

    return true
  end

  def approval_requested_for_other_venue?
    self.program.venue_schedules.each { |vs|
      return true if vs.approval_requested?
    }
    return false
  end

  # have we requested the approval for the venue?
  def approval_requested?
    !([STATE_UNKNOWN, STATE_BLOCK_REQUESTED, STATE_BLOCKED, STATE_UNAVAILABLE, STATE_CANCELLED, STATE_EXPIRED, STATE_AVAILABLE_EXPIRED].include?(self.state))
  end

  # has the payment been approved for the venue?
  def approved?
    !([STATE_UNKNOWN, STATE_BLOCK_REQUESTED, STATE_BLOCKED, STATE_APPROVAL_REQUESTED, STATE_UNAVAILABLE, STATE_CANCELLED, STATE_EXPIRED, STATE_AVAILABLE_EXPIRED].include?(self.state))
  end

  def on_program_event(event)
    valid_states = {
        ::Program::CANCELLED => [STATE_PAID, STATE_ASSIGNED],
        ::Program::DROPPED => [STATE_BLOCK_REQUESTED, STATE_BLOCKED, STATE_APPROVAL_REQUESTED],
        ::Program::ANNOUNCED => [STATE_PAID],
        ::Program::STARTED => [STATE_ASSIGNED],
        ::Program::FINISHED => [STATE_IN_PROGRESS] + (BLOCKED_STATES - PAID_STATES) + [STATE_BLOCK_REQUESTED]

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
    return true if User.current_user.is? :center_coordinator, :center_id => self.program.center_id
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def is_venue_coordinator?
    return true if User.current_user.is? :venue_coordinator, :center_id => self.program.center_id
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def is_sector_coordinator?
    return true if User.current_user.is? :sector_coordinator, :center_id => self.program.center_id
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def is_center_scheduler?
    return true if User.current_user.is? :center_scheduler, :center_id => self.program.center_id
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def is_pcc_accounts?
    return true if User.current_user.is? :pcc_accounts, :center_id => self.program.center_id
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def can_create?(center_ids = self.program.center_id)
    return true if User.current_user.is? :center_scheduler, :for => :any, :center_id => center_ids
    return false
  end

  def can_update?
    return true if User.current_user.is? :center_scheduler, :center_id => self.program.center_id
    return true if User.current_user.is? :venue_coordinator, :center_id => self.program.center_id
    return true if User.current_user.is? :pcc_accounts, :center_id => self.program.center_id
    return false
  end

  def can_view?
    self.venue.can_view_schedule?
  end

  def url
    Rails.application.routes.url_helpers.venue_schedule_url(self)
  end

  def friendly_first_name_for_email
    "Venue Schedule ##{self.id}"
  end

  def friendly_second_name_for_email
    name = " for Venue ##{self.venue_id} #{self.venue.name}"
    name += " and Program ##{self.program_id} #{self.program.name}"
  end

  def friendly_name_for_sms
    "Venue Schedule ##{self.id} for #{self.venue.name}"
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
