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


  PROCESSABLE_EVENTS = [
    :block, :request_approval, :authorize_for_payment, :request_payment, :process_payment, :cancel
  ]

  STATE_BLOCK_REQUESTED = :block_requested
  STATE_BLOCKED = :blocked
  STATE_APPROVAL_REQUESTED = :approval_requested
  STATE_AUTHORIZED_FOR_PAYMENT = :authorized_for_payment
  STATE_PAYMENT_PENDING = :payment_pending
  STATE_PAID = :paid
  STATE_ASSIGNED = :assigned
  STATE_IN_PROGRESS = :in_progress
  STATE_CONDUCTED = :conducted
  STATE_CLOSED = :closed
  STATE_CANCELLED = :cancelled

  def initialize(*args)
    super(*args)
  end

  #def setup_details!
  #  assign_details!
  #end

  state_machine :state, :initial => STATE_BLOCK_REQUESTED do
    after_transition any => :blocked do |venue_schedule, transition|
      # Check if zero payment, trigger to paid else payment pending
    end
    after_transition any => :paid do |venue_schedule, transition|
      # TODO ready for assignment
    end

    ## State and Trigger names are referred in view

    event :block do
      transition STATE_BLOCK_REQUESTED => STATE_BLOCKED
    end
    event :request_approval do
      transition STATE_BLOCKED => STATE_APPROVAL_REQUESTED
    end
    event :authorize_for_payment do
      transition STATE_APPROVAL_REQUESTED => STATE_AUTHORIZED_FOR_PAYMENT
    end
    event :request_payment do
      transition STATE_AUTHORIZED_FOR_PAYMENT => STATE_PAYMENT_PENDING
    end

    after_transition any => STATE_PAYMENT_PENDING do |vs, transition|
      unless vs.venue.paid?
        vs.process_payment()
      end
    end

    event :process_payment do
      transition [STATE_PAYMENT_PENDING] => STATE_PAID
    end

    event :assign do
      transition STATE_PAID => STATE_ASSIGNED
    end

    event :program_in_progress do
      transition STATE_ASSIGNED => STATE_IN_PROGRESS
    end

    event :program_finish do
      transition STATE_IN_PROGRESS => STATE_CONDUCTED
    end

    event :program_close do
      transition STATE_CONDUCTED => STATE_CLOSED
    end

    event :cancel do
      transition any => STATE_CANCELLED
    end

    def on_block
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
