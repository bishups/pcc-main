class KitSchedule < ActiveRecord::Base
  belongs_to :kit
  belongs_to :program
  attr_accessible :program_id, :kit_id,:end_date, :start_date,:state

  validates :start_date, :presence => true
  validates :end_date, :presence => true
  
  before_validation :assign_start_date_end_date, :assign_person_ids
  
  #checking for overlap validation 
  validates_with KitScheduleValidator
  
  state_machine :state , :initial => :blocked do
    
    event :assign do
      transition [:blocked] => :assigned
    end
    
    event :issue do
      transition [:assigned] => :issued
    end
    
    event :returned_and_check do 
      transition [:issued] => :returned_and_checked
    end
    
    event :available do
      transition [:blocked,:returned_and_checked,:under_repair, :incomplete_return] => :available
    end
    
    event :under_repair do
      transition [:blocked,:available, :returned_and_checked, :incomplete_return,:blocked] => :under_repair
    end
    
    event :incomplete_return do
      transition [:returned_and_checked] => :incomplete_return
    end
    
    event :unavailable do 
      transition [:incomplete_return,:under_repair,:available,:blocked] => :unavailable
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
