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

  acts_as_paranoid

  attr_accessible :condition,:comments, :name,
                  :state,:capacity

  has_many :kit_items
  attr_accessible :kit_items
  attr_accessor :current_user

  has_many :kit_item_names, :through => :kit_items

  has_many :kit_schedules
  has_and_belongs_to_many :centers
  attr_accessible :center_ids, :centers
  validate :has_centers?
  after_create :mark_as_available!

  belongs_to :requester, :class_name => "User"
  belongs_to :guardian, :class_name => "User" #, :foreign_key => "rated_id"
  attr_accessible :requester_id, :guardian_id, :requester, :guardian

  validates :name, :condition, :presence => true
  validates :capacity, :numericality => {:only_integer => true }

  attr_accessor :comment_category
  attr_accessible :comment_category

  has_paper_trail

  #after_create :generateKitNameStringAfterCreate
  #before_update :generateKitNameString

  STATE_UNKNOWN       = 'Unknown'
  STATE_AVAILABLE     = 'Available'

  EVENT_AVAILABLE     = 'Available'
  validates_with KitValidator


  state_machine :state, :initial => STATE_UNKNOWN do

    event EVENT_AVAILABLE do
      transition STATE_UNKNOWN => STATE_AVAILABLE
    end
  end


  def initialize(*args)
    super(*args)
  end

  def mark_as_available!
    self.send(EVENT_AVAILABLE)
  end

  def has_centers?
    self.errors.add(:centers, " required field.") if self.centers.blank?
    self.errors.add(:centers, " should belong to one sector.") if !::Sector::all_centers_in_one_sector?(self.centers)
  end




  def blockable_programs
    # the list returned here is not a confirmed list, it is a tentative list which might fail validations later
    # TODO - writing the query for confirmed list is too db intensive for now, so skipping it
    Program.where('center_id IN (?) AND start_date > ? AND state NOT IN (?)', self.center_ids, Time.zone.now, ::Program::FINAL_STATES)
  end

  def friendly_name
    ("%s" % [self.name]).parameterize
  end


  def can_view?
    return true if self.current_user.is? :any, :for => :any, :center_id => self.center_ids
    return false
  end

  # Usage --
  # 1. can_create?
  # 2. can_create? :any => true
  # if note specific default value of :any is false
  def can_create?(options={})
    if options.has_key?(:any) && options[:any] == true
      center_ids = []
    else
      center_ids = self.center_ids
    end

    return true if self.current_user.is? :kit_coordinator, :for => :any, :center_id => center_ids
    return false
  end

  def can_update?
    return true if self.current_user.is? :sector_coordinator, :for => :any, :center_id => self.center_ids
    return true if self.current_user.is? :kit_coordinator, :for => :any, :center_id => self.center_ids
    return false
  end

  def can_view_schedule?
    return true if self.current_user.is? :center_scheduler, :for => :any, :center_id => self.center_ids
    return true if self.current_user.is? :kit_coordinator, :for => :any, :center_id => self.center_ids
    return false
  end


  # TODO - this is a hack, to route the call through kit object from the UI.
  def can_create_schedule?
    kit_schedule = KitSchedule.new
    kit_schedule.current_user = self.current_user
    return kit_schedule.can_create?(self.center_ids)
  end

  # TODO - this is a hack, to route the call through kit object from the UI.
  def can_create_reserve_schedule?
    kit_schedule = KitSchedule.new
    kit_schedule.current_user = self.current_user
    return kit_schedule.can_create_reserve?(self.center_ids)
  end

  # TODO - this is a hack, to route the call through kit object from the UI.
  def can_create_overdue_or_under_repair_schedule?
    kit_schedule = KitSchedule.new
    kit_schedule.current_user = self.current_user
    return kit_schedule.can_create_overdue_or_under_repair?(self.center_ids)
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
