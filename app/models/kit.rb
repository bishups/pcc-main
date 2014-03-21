# == Schema Information
#
# Table name: kits
#
#  id                     :integer          not null, primary key
#  state                  :string(255)
#  max_participant_number :integer
#  filling_person_id      :integer
#  center_id              :integer
#  guardian_id            :integer
#  condition              :string(255)
#  condition_comments     :text
#  general_comments       :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  kit_name_string        :string(255)
#

class Kit < ActiveRecord::Base
  AVAILABLE = :available
  UNDER_REPAIR = :under_repair
  UNAVAILABLE = :unavailable

  attr_accessible :condition,:condition_comments,
                  :general_comments, :kit_name_string,
                  :center_id,:state,:max_participant_number

  has_many :kit_item_mappings
  has_many :kit_schedules
  has_many :kit_items, :through => :kit_item_mappings
  belongs_to :center
  
  has_paper_trail
  
  after_create :generateKitNameStringAfterCreate
  before_update :generateKitNameString

  EVENT_STATE_MAP = {
                      AVAILABLE => AVAILABLE.to_s,
                      UNDER_REPAIR => UNDER_REPAIR.to_s,
                      UNAVAILABLE => UNAVAILABLE.to_s
                    }


  PROCESSABLE_EVENTS = [
    AVAILABLE, UNDER_REPAIR, UNAVAILABLE
  ]

  validates_with KitValidator

  
  def initialize(*args)
    super(*args)
  end
  
  state_machine :state, :initial => :available do
    event :under_repair do
      transition [AVAILABLE,UNAVAILABLE] => :under_repair
    end
    event :unavailable do
      transition [UNDER_REPAIR,AVAILABLE] => :unavailable
    end
    event :available do 
      transition any => :available
    end
  end

  def getState
    if (self.state == UNDER_REPAIR.to_s || self.state == UNAVAILABLE.to_s)
      return self.state
    end
    #get the current schedule if any for the kit
    kitSchedule = self.kit_schedules.where("start_date <= ? AND end_date >= ?",Time.now, Time.now).order("start_date ASC")

    if( kitSchedule[0].nil? )
      return AVAILABLE
    else
      return kitSchedule[0].state
    end  
  end

  
  
  private
  def generateKitNameString
    center = Center.find(self.center_id )
    name = center.name+"_"+self.max_participant_number.to_s+"_"+self.id.to_s
    self.kit_name_string = name
  end

  def generateKitNameStringAfterCreate
    center = Center.find(self.center_id )
    name = center.name+"_"+self.max_participant_number.to_s+"_"+self.id.to_s
    self.kit_name_string = name
    self.save!
  end  

  
#canBeBlocked
end
