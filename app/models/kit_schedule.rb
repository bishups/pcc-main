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

  STATE_AVAILABLE   = "Available"

  STATE_RESERVED    = "Reserved"
  STATE_UNDER_REPAIR = "Under Repair"
  STATE_UNAVAILABLE_OVERDUE = "Overdue"

  STATE_BLOCKED     = "Blocked"
  STATE_ISSUED      = "Issued"
  STATE_ASSIGNED    = "Assigned"
  STATE_OVERDUE     = "Overdue"
  STATE_RETURNED    = "Returned"
  STATE_CANCELLED  = "Cancelled"

  FINAL_STATES = [STATE_RETURNED, STATE_CANCELLED]
  CONNECTED_STATES = [STATE_BLOCKED, STATE_ASSIGNED, STATE_ISSUED, STATE_OVERDUE]
  RESERVED_STATES = [STATE_RESERVED, STATE_UNDER_REPAIR, STATE_UNAVAILABLE_OVERDUE]

  EVENT_RESERVE    = "Reserve"
  EVENT_UNDER_REPAIR = "Under Repair"
  EVENT_UNAVAILABLE_OVERDUE = "Overdue"

  EVENT_BLOCK      = "Block"
  EVENT_ISSUE      = "Issue"
  EVENT_OVERDUE    = "Overdue"
  EVENT_CANCEL     = "Cancel"
  EVENT_RETURNED   = "Returned"

  NOTIFICATIONS = [EVENT_OVERDUE]
  NON_MENU_EVENTS = [EVENT_BLOCK, EVENT_RESERVE, EVENT_UNDER_REPAIR, EVENT_UNAVAILABLE_OVERDUE]
  PROCESSABLE_EVENTS = [EVENT_ISSUE, EVENT_RETURNED, EVENT_CANCEL]

  belongs_to :kit
  belongs_to :program
  belongs_to :issued_to_user, :class_name => User
  belongs_to :blocked_by_user, :class_name => User

  attr_accessible :program_id, :kit_id,:end_date, :start_date, :state, :comments

  validates :start_date, :presence => true
  validates :end_date, :presence => true
  validates :kit_id , :presence => true
  validates :state , :presence => true
  validates :program_id, :presence => true, :unless => :kit_reserved?
  validates_uniqueness_of :program_id, :scope => "kit_id", :unless => :kit_reserved?

  before_create :assign_start_date_end_date!#, :assign_person_ids!
  #after_create :connect_program!
  
  #checking for overlap validation 
  validates_with KitScheduleValidator


  
  def initialize(*args)
    super(*args)
  end
   
  state_machine :state , :initial => STATE_AVAILABLE do

    # TODO - clean up the kit schedule validations
    # TODO - see how to split effectively into two state machines ?
    event EVENT_BLOCK do
      transition [STATE_AVAILABLE] => STATE_BLOCKED
    end

    event ::Program::ANNOUNCED do
      transition STATE_BLOCKED => STATE_ASSIGNED
    end

    event EVENT_ISSUE do
      transition [STATE_ASSIGNED] => STATE_ISSUED
    end
    
    event EVENT_RETURNED do
      transition [STATE_OVERDUE, STATE_ISSUED] => STATE_RETURNED , :if => :canChangeState?
    end
    
    event EVENT_OVERDUE do
      transition [STATE_BLOCKED, STATE_ISSUED, STATE_ASSIGNED] => STATE_OVERDUE
    end

    event EVENT_CANCEL do
      transition [STATE_BLOCKED] => STATE_CANCELLED
    end

    event ::Program::DROPPED do
      transition [STATE_BLOCKED] => STATE_CANCELLED
    end

    event ::Program::CANCELLED do
      transition [STATE_ASSIGNED] => STATE_CANCELLED
    end

    event EVENT_RESERVE do
      transition [STATE_AVAILABLE] => STATE_RESERVED
    end

    event EVENT_UNDER_REPAIR do
      transition [STATE_AVAILABLE] => STATE_UNDER_REPAIR
    end

    event EVENT_UNAVAILABLE_OVERDUE do
      transition [STATE_AVAILABLE] => STATE_UNAVAILABLE_OVERDUE
    end
    before_transition STATE_AVAILABLE => [STATE_RESERVED, STATE_UNDER_REPAIR, STATE_UNAVAILABLE_OVERDUE], :do => :reserve_fields_present?

  end

  def kit_reserved?
    RESERVED_STATES.include?(self.state)
  end

  def reserve_fields_present?
    if self.comments.blank?
      self.errors[:comments] << " cannot be blank."
      return false
    end
    true
  end

  def is_connected?
    self.program_id && CONNECTED_STATES.include?(self.state)
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

  def on_program_event(event)

  end
  
end
