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

  STATE_AVAILABLE     = 'Available'
  STATE_UNDER_REPAIR  = 'Under Repair'
  STATE_UNAVAILABLE   = 'Unavailable'

  EVENT_AVAILABLE     = 'Available'
  EVENT_UNDER_REPAIR  = 'Under Repair'
  EVENT_UNAVAILABLE   = 'Not Available'

  attr_accessible :condition,:condition_comments,
                  :general_comments, :name,
                  :state,:capacity

  has_many :kit_items
  attr_accessible :kit_items

  has_many :kit_item_names, :through => :kit_items

  has_many :kit_schedules
  has_and_belongs_to_many :centers
  attr_accessible :center_ids, :centers
  validate :has_centers?

  belongs_to :requester, :class_name => "User"
  belongs_to :guardian, :class_name => "User" #, :foreign_key => "rated_id"
  attr_accessible :requester_id, :guardian_id, :requester, :guardian

  validates :name, :condition, :presence => true
  validates :capacity, :numericality => {:only_integer => true }

  has_paper_trail
  
  #after_create :generateKitNameStringAfterCreate
  #before_update :generateKitNameString



  PROCESSABLE_EVENTS = [
    EVENT_AVAILABLE, EVENT_UNDER_REPAIR, EVENT_UNAVAILABLE
  ]

  validates_with KitValidator

  
  def initialize(*args)
    super(*args)
  end

  def has_centers?
    self.errors.add(:centers, " required field.") if self.centers.blank?
    self.errors.add(:centers, " should belong to one sector.") if !::Sector::all_centers_in_one_sector?(self.centers)
  end

  state_machine :state, :initial => EVENT_AVAILABLE do
    event EVENT_UNDER_REPAIR do
      transition [STATE_AVAILABLE, STATE_UNAVAILABLE] => STATE_UNDER_REPAIR
    end
    event EVENT_UNAVAILABLE do
      transition [STATE_UNDER_REPAIR, STATE_AVAILABLE] => STATE_UNAVAILABLE
    end
    event EVENT_AVAILABLE do
      transition any => STATE_AVAILABLE
    end
  end

  def getState
    if (self.state == STATE_UNDER_REPAIR || self.state == STATE_UNAVAILABLE)
      return self.state
    end
    #get the current schedule if any for the kit
    kitSchedule = self.kit_schedules.where("start_date <= ? AND end_date >= ?",Time.zone.now, Time.zone.now).order("start_date ASC")

    if( kitSchedule[0].nil? )
      return STATE_AVAILABLE
    else
      return kitSchedule[0].state
    end  
  end

  def blockable_programs
    # the list returned here is not a confirmed list, it is a tentative list which might fail validations later
    # TODO - writing the query for confirmed list is too db intensive for now, so skipping it
    Program.where('center_id IN (?) AND start_date > ? AND state NOT IN (?)', self.center_ids, Time.zone.now, ::Program::FINAL_STATES)
  end

  def friendly_name
    ("%s" % [self.name]).parameterize
  end

=begin
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
=end

#canBeBlocked

  rails_admin do
    navigation_label 'Kit Management'
    weight 0
    visible do
      bindings[:controller].current_user.is?(:kit_coordinator)
    end
    list do
      field :name
      field :capacity
      field :condition
      field :centers
      field :kit_item_names
    end
    edit do
      field :name
      field :capacity
      field :condition
      #field :kit_items do
      #  help 'Type any character to search for kit item'
      #  #inline_add false
      #end
      field :centers  do
        help 'Type any character to search for center'
        inline_add false
        associated_collection_cache_all true  # REQUIRED if you want to SORT the list as below
        associated_collection_scope do
          # bindings[:object] & bindings[:controller] are available, but not in scope's block!
          accessible_centers = bindings[:controller].current_user.accessible_centers(:kit_coordinator)
          Proc.new { |scope|
            # scoping all Players currently, let's limit them to the team's league
            # Be sure to limit if there are a lot of Players and order them by position
           # scope = scope.where(:id => accessible_centers )
            scope = scope.where(:id => accessible_centers )
          }
        end
       end
    end
  end
end
