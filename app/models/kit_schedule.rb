class KitSchedule < ActiveRecord::Base

  UNAVAILABLE = :unavailable
  BLOCKED = :blocked
  ISSUED = :issued
  ASSIGNED = :assigned
  RETURNED_AND_CHECKED = :returned_and_checked
  UNDER_REPAIR = :under_repair
  INCOMPLETE_RETURN = :incomplete_return
  CANCELLLED = :cancelled
  
  belongs_to :kit
  belongs_to :program
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
  validates_uniqueness_of :program_id


  EVENT_STATE_MAP = { UNAVAILABLE => UNAVAILABLE.to_s,
                      BLOCKED => BLOCKED.to_s,
                      ISSUED => ISSUED.to_s,
                      ASSIGNED => ASSIGNED.to_s,
                      RETURNED_AND_CHECKED => RETURNED_AND_CHECKED.to_s,
                      UNDER_REPAIR => UNDER_REPAIR.to_s,
                      INCOMPLETE_RETURN => INCOMPLETE_RETURN.to_s,
                      CANCELLLED => CANCELLLED.to_s
                    }

  PROCESSABLE_EVENTS = [
    BLOCKED, ASSIGNED, ISSUED, RETURNED_AND_CHECKED, UNDER_REPAIR, INCOMPLETE_RETURN, UNAVAILABLE, CANCELLLED
  ]
  
  state_machine :state , :initial => BLOCKED do

    event :block do
      transition [INCOMPLETE_RETURN, RETURNED_AND_CHECKED, UNDER_REPAIR] => BLOCKED
    end
    
    event :assign do
      transition [BLOCKED] => ASSIGNED
    end
    
    event :issue do
      transition [ASSIGNED] => ISSUED
    end
    
    event :returned_and_check do 
      transition [ISSUED] => RETURNED_AND_CHECKED
    end
    
    event :under_repair do
      transition [BLOCKED, RETURNED_AND_CHECKED, INCOMPLETE_RETURN,BLOCKED] => UNDER_REPAIR
    end
    
    event :incomplete_return do
      transition [RETURNED_AND_CHECKED] => INCOMPLETE_RETURN
    end

    event :unavailable do 
      transition [INCOMPLETE_RETURN,UNDER_REPAIR,BLOCKED] => UNAVAILABLE
    end

    event :cancel do
      transition [:any] => CANCELLLED
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
    
    prog = Program.find(self.program_id)
    self.start_date = prog.start_date - 1
    self.end_date = prog.end_date + 1 
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
  
end
