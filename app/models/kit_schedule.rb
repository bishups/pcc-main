# == Schema Information
#
# Table name: kit_schedules
#
#  id                   :integer          not null, primary key
#  start_date           :date
#  end_date             :date
#  state                :string(255)
#  issued_to_person_id  :integer
#  blocked_by_person_id :integer
#  program_id           :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  comments             :string(255)
#  kit_id               :integer
#

class KitSchedule < ActiveRecord::Base

  STATE_BLOCKED     = "Blocked"
  STATE_ISSUED      = "Issued"
  STATE_ASSIGNED    = "Assigned"
  STATE_OVERDUE     = "Overdue"
  STATE_CANCELLED  = "Cancelled"
  STATE_CLOSED      = "Closed"

  EVENT_BLOCK      = "Block"
  EVENT_ISSUE      = "Issue"
  EVENT_ASSIGN     = "Assign"
  EVENT_OVERDUE    = "Overdue"
  EVENT_CANCEL     = "Cancel"
  EVENT_CLOSE      = "Close"

  belongs_to :kit
  belongs_to :program
  belongs_to :issued_to_user, :class_name => User
  belongs_to :blocked_by_user, :class_name => User

  attr_accessible :program_id, :kit_id,:end_date, :start_date,:state

  validates :start_date, :presence => true
  validates :end_date, :presence => true
  validates :kit_id , :presence => true
  validates :state , :presence => true
  validates :program_id, :presence => true
  validates_uniqueness_of :program_id, :scope => "kit_id"

  before_create :assign_start_date_end_date!#, :assign_person_ids!
  #after_create :connect_program!
  
  #checking for overlap validation 
  validates_with KitScheduleValidator

  PROCESSABLE_EVENTS = [
      EVENT_BLOCK, EVENT_ASSIGN, EVENT_ISSUE, EVENT_OVERDUE, EVENT_CLOSE, EVENT_CANCEL
  ]

  
  def initialize(*args)
    super(*args)
  end
   
  state_machine :state , :initial => STATE_BLOCKED do

    event EVENT_ASSIGN do
      transition [STATE_BLOCKED] => STATE_ASSIGNED, :if => :canChangeState?
    end
    
    event EVENT_ISSUE do
      transition [STATE_ASSIGNED] => STATE_ISSUED, :if => :canChangeState?
    end
    
    event EVENT_CLOSE do
      transition [STATE_ISSUED] => STATE_CLOSED , :if => :canChangeState?
    end
    
    event EVENT_OVERDUE do
      transition [STATE_BLOCKED, STATE_ISSUED, STATE_ASSIGNED] => STATE_OVERDUE
    end

    event EVENT_CANCEL do
      transition [STATE_BLOCKED, STATE_ASSIGNED] => STATE_CANCELLED
    end
  end

  def set_up_details!
    assign_start_date_end_date!
    # TODO - this will anyway be called during the save
    #assign_person_ids!
  end
  
  def assign_start_date_end_date!
    if self.program_id.nil?
      return
    end    
    prog = Program.find_by_id(self.program_id)
    if prog
      self.start_date = prog.start_date - 1.day
      self.end_date = prog.end_date + 1.day
    else
      # http://www.elabs.se/blog/36-working-with-time-zones-in-ruby-on-rails
      self.start_date = Date.current
      self.end_date = Date.current
    end

  end

  # TODO - need to fix this
  def assign_person_ids!
    if self.state.nil?
      return
    end
    if self.state == STATE_BLOCKED
      self.blocked_by_user_id = current_user.id
    elsif self.state == STATE_ISSUED
       self.issued_to_user_id = current_user.id
    end 
  end

  #def connect_program!
  #  self.program.connect_kit(self) unless self.program.nil?
  #end

  def canChangeState?
    if self.kit.state != ::Kit::STATE_AVAILABLE
      return false
    else
      return true  
    end
  end

  def can_assign?
    if self.kit.state != ::Kit::STATE_AVAILABLE
      return false
    else
      return true  
    end
  end

  def assigned!
    self.state = STATE_ASSIGNED
  end
  
end
