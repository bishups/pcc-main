# == Schema Information
#
# Table name: kits
#
#  id                      :integer          not null, primary key
#  state                   :string(255)
#  guardian_id             :integer
#  condition               :string(255)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  name                    :string(255)
#  capacity                :integer
#  deleted_at              :datetime
#  comments                :text
#  last_update             :string(255)
#  last_updated_by_user_id :integer
#  last_updated_at         :datetime
#

class Kit < ActiveRecord::Base
  include CommonFunctions
  has_many :activity_logs, :as => :model, :inverse_of => :model
  has_many :notification_logs, :as => :model, :inverse_of => :model

  acts_as_paranoid

  attr_accessible :condition,:comments, :name,
                  :state,:capacity

  has_many :kit_items
  attr_accessible :kit_items, :kit_items_attributes
  accepts_nested_attributes_for :kit_items, :allow_destroy => true
  attr_accessor :current_user

  has_many :kit_item_types, :through => :kit_items

  belongs_to :last_updated_by_user, :class_name => User
  attr_accessible :last_update, :last_updated_at

  has_many :kit_schedules
  has_and_belongs_to_many :centers
  attr_accessible :center_ids, :centers
  validate :has_centers?
  after_create :mark_as_available!

  belongs_to :guardian, :class_name => "User" #, :foreign_key => "rated_id"
  attr_accessible :guardian_id, :guardian

  validates :name, :condition, :guardian, :presence => true
  validates_uniqueness_of :name, :scope => :deleted_at

  validates :capacity, :presence => true,  :length => {:within => 1..4}, :numericality => {:only_integer => true }

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

    after_transition any => any do |object, transition|
      object.store_last_update!(object.current_user, transition.from, transition.to, transition.event)
      object.notify(transition.from, transition.to, transition.event, object.centers)
    end
  end


  def initialize(*args)
    super(*args)
  end

  def mark_as_available!

    #self.send(EVENT_AVAILABLE) if self.state == ::Kit::STATE_UNKNOWN

    # HACK #1 - all this making the centers dirty and reloading the object
    # due to open rails bug when trying to save a model with habtm in after_create
    # https://rails.lighthouseapp.com/projects/8994/tickets/4553-habtm-association-failure-to-save-in-join-table-with-after_create-callback
    # HACK #2 - after HACK #1, some problem with doing a send to state machine
    # so setting the state directly and logging in the current context only
    if self.state == STATE_UNKNOWN
      centers = self.centers
      self.reload
      self.state = STATE_AVAILABLE
      self.centers = centers
      self.store_last_update!(nil, STATE_UNKNOWN, STATE_AVAILABLE, EVENT_AVAILABLE)
      self.notify(STATE_UNKNOWN, STATE_AVAILABLE, EVENT_AVAILABLE, self.centers)
      self.save
    end
  end

  def has_centers?
    self.errors.add(:centers, " required field.") if self.centers.blank?
    #self.errors.add(:centers, " should belong to one sector.") if !::Sector::all_centers_in_one_sector?(self.centers)
    self.errors.add(:centers, " should belong to one zone.") if !::Zone::all_centers_in_one_zone?(self.centers)
  end




  def blockable_programs
    # NOTE: We **can** add a kit even after the program has started
    programs = Program.where('center_id IN (?) AND end_date > ? AND state NOT IN (?)', self.center_ids, Time.zone.now, ::Program::CLOSED_STATES).order('start_date ASC').all
    blockable_programs = []
    programs.each {|program|
      blockable_programs << program if self.can_be_blocked_by?(program)
    }
    blockable_programs
  end

  def can_be_blocked_by?(program)
    ks = KitSchedule.new
    ks.assign_dates!(program)
    ks.kit_id = self.id
    KitSchedule.overlapping_schedules(ks).count == 0
  end


  def friendly_name
    ("#%d %s" % [self.id, self.name])
  end

  def url
    Rails.application.routes.url_helpers.kit_url(self)
  end

  def friendly_first_name_for_email
    "Kit ##{self.id}"
  end

  def friendly_second_name_for_email
    " #{self.name}"
  end

  def friendly_name_for_sms
    "Kit ##{self.id} #{self.name}"
  end


  def can_view?
    return true if User.current_user.is? :any, :for => :any, :in_group => [:geography], :center_id => self.center_ids
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

    return true if User.current_user.is? :kit_coordinator, :for => :any, :center_id => center_ids
    return false
  end

  def can_update?
    # This condition is not needed
    #return true if User.current_user.is? :sector_coordinator, :for => :any, :center_id => self.center_ids
    return true if User.current_user.is? :kit_coordinator, :for => :any, :center_id => self.center_ids
    return false
  end

  def can_view_schedule?
    return true if User.current_user.is? :center_scheduler, :for => :any, :center_id => self.center_ids
    return true if User.current_user.is? :kit_coordinator, :for => :any, :center_id => self.center_ids
    return false
  end


  # HACK - to route the call through kit object from the UI.
  def can_create_schedule?
    kit_schedule = KitSchedule.new
    kit_schedule.current_user = User.current_user
    return kit_schedule.can_create?(self.center_ids)
  end

  # HACK - to route the call through kit object from the UI.
  def can_create_reserve_schedule?
    kit_schedule = KitSchedule.new
    kit_schedule.current_user = User.current_user
    return kit_schedule.can_create_reserve?(self.center_ids)
  end

  # HACK - to route the call through kit object from the UI.
  def can_create_overdue_or_under_repair_schedule?
    kit_schedule = KitSchedule.new
    kit_schedule.current_user = User.current_user
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
      field :guardian
      field :capacity
      field :condition
      field :centers
      field :kit_item_types
    end
    edit do
      # to get the current user from the rails-admin view
      field :current_user, :hidden do
        read_only true
        default_value do
          bindings[:object].current_user = bindings[:view].current_user
        end
      end
      field :name
      field :guardian do
        inline_edit false
        inline_add false
        associated_collection_cache_all true  # REQUIRED if you want to SORT the list as below
        associated_collection_scope do
          # bindings[:object] & bindings[:controller] are available, but not in scope's block!
          accessible_centers_users = bindings[:controller].current_user.accessible_centers.map(&:user_ids).flatten.uniq
          Proc.new { |scope|
            scope = scope.where(:id => accessible_centers_users )
          }
        end
      end
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
      field :kit_items
    end
  end
end
