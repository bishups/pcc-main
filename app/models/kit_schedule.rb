class KitSchedule < ActiveRecord::Base
  belongs_to :kit
  attr_accessor :assigned_to_program_id, :blocked_by_person_id, :auto_shop_busy, :issued_to_person_id, :state, :end_date, :start_date
  
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
  
end
