class VenueSchedule < ActiveRecord::Base
  # attr_accessible :title, :body
  attr_accessible :slot
  attr_accessible :start_date
  attr_accessible :end_date
  attr_accessible :program_id

  validates :start_date, :presence => true
  validates :end_date, :presence => true
  validates :slot, :presence => true
  validates :reserving_user_id, :presence => true

  # Overlap validation
  validates_with VenueScheduleValidator
  validates_uniqueness_of :program_id

  belongs_to :venue
  belongs_to :reserving_user, :class_name => User
  belongs_to :program

  before_create :assign_details!
  after_create :connect_program!

  def initialize(*args)
    super(*args)
  end

  def setup_details!
    assign_details!
  end

  state_machine :state, :initial => :block_requested do
    after_transition any => :blocked do |venue_schedule, transition|
      # Check if zero payment, trigger to paid else payment pending
    end
    after_transition any => :paid do |venue_schedule, transition|
      # TODO ready for assignment
    end

    ## State and Trigger names are referred in view

    event :block do
      transition :block_requested => :blocked
    end
    event :request_payment do
      transition :blocked => :payment_pending
    end
    event :process_payment do
      transition [:blocked, :payment_pending] => :paid
    end
    event :cancel do
      transition any => :cancelled
    end
  end

  private

  def assign_details!
    program = ::Program.find(self.program_id)
    self.slot = program.slot
    self.start_date = program.start_date
    self.end_date = program.end_date
    self.end_date = Time.now + 20.days if self.end_date.nil?
  end

  def connect_program!
    self.program.connect_venue(self)
  end

end
