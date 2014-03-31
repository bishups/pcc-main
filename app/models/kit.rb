# == Schema Information
#
# Table name: kits
#
#  id                     :integer          not null, primary key
#  state                  :string(255)
#  capacity :integer
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
                  :general_comments, :name,
                  :state,:capacity

  has_many :kit_items
  attr_accessible :kit_item_ids, :kit_items

  has_many :kit_schedules
  has_and_belongs_to_many :centers
  attr_accessible :center_ids, :centers
  validate :has_centers?

  belongs_to :requester, :class_name => "User"
  belongs_to :guardian, :class_name => "User" #, :foreign_key => "rated_id"
  attr_accessible :requester_id, :guardian_id, :requester, :guardian

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

  def has_centers?
    self.errors.add(:centers, "Kit needs to be associated to center(s).") if self.centers.blank?
    self.errors.add(:centers, " should belong to one sector.") if ::Sector::all_centers_in_one_sector?(self.centers)
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
    name = center.name+"_"+self.capacity.to_s+"_"+self.id.to_s
    self.name = name
  end

  def generateKitNameStringAfterCreate
    center = Center.find(self.center_id )
    name = center.name+"_"+self.capacity.to_s+"_"+self.id.to_s
    self.name = name
    self.save!
  end


#canBeBlocked

  rails_admin do
    list do
      field :name
      field :capacity
      field :kit_items
      field :centers
      field :condition
    end
    edit do
      field :name
      field :capacity
      field :kit_items do
        help 'Type any character to search for kit item'
        inline_add do
          false
        end
      end
      field :centers  do
        help 'Type any character to search for center'
        inline_add do
          false
        end
      end
      field :condition
    end

  end
end
