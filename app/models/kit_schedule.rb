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

  BLOCKED = :blocked
  ISSUED = :issued
  ASSIGNED = :assigned
  OVERDUE = :over_due
  CANCELLLED = :cancel
  CLOSED = :closed
  
  belongs_to :kit
  belongs_to :program
  belongs_to :issued_to_person, :class_name => User
  belongs_to :blocked_by_person, :class_name => User

  attr_accessible :program_id, :kit_id,:end_date, :start_date,:state

  validates :start_date, :presence => true
  validates :end_date, :presence => true
  validates :kit_id , :presence => true
  validates :state , :presence => true
  validates :program_id, :presence => true
  
  before_create :assign_start_date_end_date!, :assign_person_ids!
  after_create :connect_program!
  
  #checking for overlap validation 
  validates_with KitScheduleValidator

  EVENT_STATE_MAP = {
                      BLOCKED => "block",
                      ISSUED => "issue",
                      ASSIGNED => "assign",
                      OVERDUE => OVERDUE.to_s,
                      CANCELLLED => CANCELLLED.to_s,
                      CLOSED => CLOSED.to_s
                    }

  PROCESSABLE_EVENTS = [
    BLOCKED, ASSIGNED, ISSUED, OVERDUE,CLOSED, CANCELLLED
  ]
   
  state_machine :state , :initial => BLOCKED do

    event :assign do
      transition [BLOCKED] => ASSIGNED, :if => :canChangeState?
    end
    
    event :issue do
      transition [ASSIGNED] => ISSUED, :if => :canChangeState?
    end
    
    event :closed do 
      transition [ISSUED] => CLOSED , :if => :canChangeState?
    end
    
    event :over_due do
      transition [BLOCKED,ISSUED,ASSIGNED] => OVERDUE 
    end

    event :cancel do
      transition [BLOCKED,ASSIGNED] => CANCELLLED
    end
  end

  def set_up_details!
    assign_start_date_end_date!
    assign_person_ids!
  end
  
  def assign_start_date_end_date!
    if self.program_id.nil?
      return
    end    
    prog = Program.find_by_id(self.program_id)
    if prog
      self.start_date = prog.start_date - 1
      self.end_date = prog.end_date + 1 
    else
      self.start_date = Date.today
      self.end_date = Date.today
    end

  end

  def assign_person_ids!
    if self.state.nil?
      return
    end
    if self.state == BLOCKED
      self.blocked_by_person_id = current_user.id
    elsif self.state == ISSUED
       self.issued_to_person_id = current_user.id 
    end 
  end

  def connect_program!
    self.program.connect_kit(self) unless self.program.nil?
  end

  def canChangeState?
    if self.kit.state != ::Kit::AVAILABLE.to_s
      return false
    else
      return true  
    end
  end

  def can_assign?
    if self.kit.state != ::Kit::AVAILABLE.to_s
      return false
    else
      return true  
    end
  end

  def assigned!
    self.state = ASSIGNED    
  end
  
end
