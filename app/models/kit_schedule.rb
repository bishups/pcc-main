class KitSchedule < ActiveRecord::Base

  UNAVAILABLE = :unavailable
  BLOCKED = :blocked
  ISSUED = :issued
  ASSIGNED = :assigned
  RETURNED_AND_CHECKED = :returned_and_checked
  UNDER_REPAIR = :under_repair
  INCOMPLETE_RETURN = :incomplete_return


  belongs_to :kit
  belongs_to :program
  attr_accessible :program_id, :kit_id,:end_date, :start_date,:state

  validates :start_date, :presence => true
  validates :end_date, :presence => true
  
  before_validation :assign_start_date_end_date, :assign_person_ids
  
  #checking for overlap validation 
  validates_with KitScheduleValidator
  
  state_machine :state , :initial => BLOCKED do
    
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
    
  end
  
  def assign_start_date_end_date
    prog = Program.find(self.program_id)
    self.start_date = prog.start_date - 1
    self.end_date = prog.end_date + 1 
  end

  def assign_person_ids
    if self.state == "Blocked"
      self.blocked_by_person_id = current_user.id
    elsif self.state == "Issued"
       self.issued_to_person_id = current_user.id 
    end 
  end

  def connect_program!
    self.program.connect_kit(self)
  end
  
end
