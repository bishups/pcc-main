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
  scope :overlapping, lambda { |vs| joins(:program).merge(Program.overlapping(vs.program)).where('venue_schedules.id != ? AND venue_schedules.state != ?', vs.id, ::VenueSchedule::STATE_CANCELLED) }

  # given a venue_schedule, returns a relation with other non-overlapping venue_schedule(s)
  scope :available, lambda { |vs| joins(:program).merge(Program.available(vs.program)).where('venue_schedules.id != ? AND venue_schedules.state != ?', vs.id, ::VenueSchedule::STATE_CANCELLED) }


  STATE_BLOCK_REQUESTED           = "Block Requested"
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

  EVENT_BLOCK             = "Block"
  EVENT_REQUEST_APPROVAL  = "Request Approval"
  EVENT_AUTHORIZE_FOR_PAYMENT = "Authorize for Payment"
  EVENT_REQUEST_PAYMENT   = "Request Payment"
  EVENT_PROCESS_PAYMENT   = "Process Payment"
  EVENT_CANCEL            = "Cancel"

  PROCESSABLE_EVENTS = [
    EVENT_BLOCK, EVENT_REQUEST_APPROVAL, EVENT_AUTHORIZE_FOR_PAYMENT, EVENT_REQUEST_PAYMENT, EVENT_PROCESS_PAYMENT, EVENT_CANCEL
  ]

  def initialize(*args)
    super(*args)
  end

  #def setup_details!
  #  assign_details!
  #end

  state_machine :state, :initial => STATE_BLOCK_REQUESTED do
    after_transition any => STATE_BLOCKED do |venue_schedule, transition|
      # Check if zero payment, trigger to paid else payment pending
    end
    after_transition any => STATE_PAID do |venue_schedule, transition|
      # TODO ready for assignment
    end

    ## State and Trigger names are referred in view

    event EVENT_BLOCK do
      transition STATE_BLOCK_REQUESTED => STATE_BLOCKED
    end
    event EVENT_REQUEST_APPROVAL do
      transition STATE_BLOCKED => STATE_APPROVAL_REQUESTED
    end
    event EVENT_AUTHORIZE_FOR_PAYMENT do
      transition STATE_APPROVAL_REQUESTED => STATE_AUTHORIZED_FOR_PAYMENT
    end
    event EVENT_REQUEST_PAYMENT do
      transition STATE_AUTHORIZED_FOR_PAYMENT => STATE_PAYMENT_PENDING
    end

    after_transition any => STATE_PAYMENT_PENDING do |vs, transition|
      unless vs.venue.paid?
        vs.process_payment()
      end
    end

    event EVENT_PROCESS_PAYMENT do
      transition [STATE_PAYMENT_PENDING] => STATE_PAID
    end

    event ::Program::ANNOUNCED do
      transition STATE_PAID => STATE_ASSIGNED
    end

    event ::Program::STARTED do
      transition STATE_ASSIGNED => STATE_IN_PROGRESS
    end

    event ::Program::FINISHED do
      transition STATE_IN_PROGRESS => STATE_CONDUCTED
    end

   # event ::Program::CLOSED do
   #   transition STATE_CONDUCTED => STATE_CLOSED
   # end

    event EVENT_CANCEL do
      transition STATE_BLOCK_REQUESTED => STATE_CANCELLED
    end

    event ::Program::DROPPED do
      transition [STATE_BLOCK_REQUESTED, STATE_BLOCKED, STATE_APPROVAL_REQUESTED] => STATE_CANCELLED
    end

    event ::Program::CANCELLED do
      transition [STATE_PAID, STATE_ASSIGNED] => STATE_CANCELLED
    end

    def on_block
    end
  end

  # have we requested the approval for the venue?
  def approval_requested?
    !([STATE_BLOCK_REQUESTED, STATE_BLOCKED, STATE_CANCELLED].include?(self.state))
  end

  # has the payment been approved for the venue?
  def approved?
    !([STATE_BLOCK_REQUESTED, STATE_BLOCKED, STATE_APPROVAL_REQUESTED, STATE_CANCELLED].include?(self.state))
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
