# == Schema Information
#
# Table name: venues
#
#  id              :integer          not null, primary key
#  center_id       :integer
#  zone_id         :integer
#  name            :string(255)
#  description     :text
#  address         :text
#  pin_code        :string(255)
#  capacity        :string(255)
#  state           :string(255)
#  contact_name    :string(255)
#  contact_email   :string(255)
#  contact_phone   :string(255)
#  contact_mobile  :string(255)
#  contact_address :text
#  commercial      :boolean
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Venue < ActiveRecord::Base
  include CommonFunctions


  acts_as_paranoid

  # attr_accessible :title, :body
  attr_accessor :current_user
  attr_accessible :name, :description, :address, :pin_code, :capacity, :contact_name, :contact_phone,
  :contact_mobile, :contact_email, :contact_address, :commercial, :payment_contact_name,
  :payment_contact_address,:payment_contact_mobile,:per_day_price

  after_create :mark_as_proposed!
  has_and_belongs_to_many :centers
  attr_accessible :center_ids, :centers
  validate :has_centers?
  validate :has_per_day_price?
  validate :has_commercial?

  belongs_to :last_updated_by_user, :class_name => User
  attr_accessible :last_update, :last_updated_at

  has_many :venue_schedules

  attr_accessor :comment_category
  attr_accessible :comment_category

  validates_presence_of :address
  #validates_presence_of :center_id
  validates :name, :presence => true, :uniqueness => true
  validates :capacity, :presence => true,  :length => {:within => 1..4}, :numericality => {:only_integer => true }
  validates :contact_mobile, :presence => true, :length => { is: 10}, :numericality => {:only_integer => true }
  validates :pin_code, :presence => true, :length => { is: 6}, :numericality => {:only_integer => true }
  validates :per_day_price, :numericality => true, :allow_nil => true

  validates :payment_contact_mobile, :length => { is: 10}, :numericality => {:only_integer => true }, :allow_blank => true
  validates :contact_email, :format => {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}, :allow_blank => true
  validates :contact_phone, :length => { is: 12}, :format => {:with => /0[0-9]{2,4}-[0-9]{6,8}/i}, :allow_blank => true

  STATE_UNKNOWN         = "Unknown"
  STATE_PROPOSED        = "Proposed"
  STATE_APPROVED        = "Approved"
  STATE_REJECTED        = "Rejected"
  STATE_POSSIBLE        = "Possible"
  STATE_PENDING_FINANCE_APPROVAL = "Pending Finance Approval"
  STATE_INSUFFICIENT_INFO = "Insufficient Info"

  FINAL_STATES = []

  EVENT_PROPOSE          = "Propose"
  EVENT_APPROVE          = "Approve"
  EVENT_REJECT           = "Reject"
  EVENT_POSSIBLE        = "Possible"
  EVENT_INSUFFICIENT_INFO = "Insufficient Info"
  EVENT_REQUEST_FINANCE_APPROVAL = "Request Finance Approval"
  EVENT_FINANCE_APPROVAL  = "Finance Approval"

  PROCESSABLE_EVENTS = [
    EVENT_APPROVE, EVENT_REJECT, EVENT_INSUFFICIENT_INFO, EVENT_FINANCE_APPROVAL, EVENT_REQUEST_FINANCE_APPROVAL
  ]

  EVENTS_WITH_COMMENTS = [EVENT_REJECT]
  EVENTS_WITH_FEEDBACK = []

  state_machine :state, :initial => STATE_UNKNOWN do

    event EVENT_PROPOSE do
      transition STATE_UNKNOWN => STATE_PROPOSED #, :if => lambda {|t| t.can_create?}
    end
    #before_transition STATE_UNKNOWN => STATE_PROPOSED, :do => :can_propose?

    event EVENT_APPROVE do
      transition [STATE_PROPOSED, STATE_REJECTED] => STATE_APPROVED, :if => lambda {|t| t.is_sector_coordinator? }
    end
    before_transition any => STATE_APPROVED, :do => :is_sector_coordinator?

    after_transition any => STATE_APPROVED do |venue, transition|
      if venue.free?
        venue.send(EVENT_POSSIBLE)
      else
        venue.send(EVENT_REQUEST_FINANCE_APPROVAL)
      end
    end

    event EVENT_REQUEST_FINANCE_APPROVAL do
      transition STATE_APPROVED => STATE_PENDING_FINANCE_APPROVAL
      transition STATE_INSUFFICIENT_INFO => STATE_PENDING_FINANCE_APPROVAL, :if => lambda {|t| t.is_pcc_accounts? }
    end
    before_transition STATE_INSUFFICIENT_INFO => STATE_PENDING_FINANCE_APPROVAL, :do => :is_pcc_accounts?

    event EVENT_FINANCE_APPROVAL do
      transition STATE_PENDING_FINANCE_APPROVAL => STATE_POSSIBLE, :if => lambda {|t| t.is_pcc_accounts? }
    end
    before_transition STATE_PENDING_FINANCE_APPROVAL => STATE_POSSIBLE, :do => :is_pcc_accounts?

    event EVENT_POSSIBLE do
      transition STATE_APPROVED => STATE_POSSIBLE
    end

    event EVENT_REJECT do
      transition [STATE_PROPOSED, STATE_POSSIBLE] => STATE_REJECTED, :if => lambda {|t| t.is_sector_coordinator? }
    end
    before_transition [STATE_PROPOSED, STATE_POSSIBLE] => STATE_REJECTED, :do => :can_reject?

    event EVENT_INSUFFICIENT_INFO do
      transition STATE_PENDING_FINANCE_APPROVAL => STATE_INSUFFICIENT_INFO, :if => lambda {|t| t.is_pcc_accounts? }
    end
    before_transition STATE_PENDING_FINANCE_APPROVAL => STATE_INSUFFICIENT_INFO, :do => :is_pcc_accounts?

    # check for comments, before any transition
    before_transition any => any do |object, transition|
      # Don't return here, else LocalJumpError will occur
      if EVENTS_WITH_COMMENTS.include?(transition.event) && !object.has_comments?
        false
      elsif EVENTS_WITH_FEEDBACK.include?(transition.event) && !object.has_feedback?
        false
      else
        true
      end
    end

    after_transition any => any do |object, transition|
      object.store_last_update!(object.current_user, transition.from, transition.to, transition.event)
      object.notify(transition.from, transition.to, transition.event, object.centers)
    end

  end

  def can_propose?
    unless self.can_create?
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    end
    return true
  end


  def initialize(*args)
    super(*args)
  end

  def mark_as_proposed!
    self.send(::Venue::EVENT_PROPOSE) if self.state == ::Venue::STATE_UNKNOWN
    # HACK - some problem with doing a send to state machine and then logging notification
    # so setting the state directly and logging in the current context only
    #self.state = STATE_PROPOSED if self.state == STATE_UNKNOWN
    # TODO - see how we can get the current_user here?
    #self.store_last_update!(nil, STATE_UNKNOWN, STATE_PROPOSED, EVENT_PROPOSE)
    #self.notify(STATE_UNKNOWN, STATE_PROPOSED, EVENT_PROPOSE, self.centers)
  end

  def blockable_programs
    # NOTE: We **can** add a venue even after the program has started
    programs = Program.where('center_id IN (?) AND end_date > ? AND state NOT IN (?)', self.center_ids, Time.zone.now, ::Program::CLOSED_STATES).order('start_date ASC').all
    blockable_programs = []
    programs.each {|program|
      blockable_programs << program if venue.can_be_blocked_by?(program)
    }
    blockable_programs
  end

  def can_be_blocked_by?(program)
    VenueSchedule.all_overlapping(self, program).count == 0
  end


def can_reject?
    unless self.is_sector_coordinator?
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    end

    if self.is_active?
      self.errors[:base] << "Cannot reject the venue, it has active schedules. Please close the schedules and try again."
      return false
    end
    return true
  end

  def is_active?
    return false if !self.venue_schedules
    self.venue_schedules.each { |vs|
      return true if vs.is_active?
    }
    return false
  end

  def free?
    self.per_day_price.to_i == 0
  end

  def possible?
    self.state == STATE_POSSIBLE
  end

  def current_schedule
    self.venue_schedules.where('start_date < ? AND end_date > ?', Time.zone.now, Time.zone.now).first()
  end

  def current_state
    vs = current_schedule
    vs ? vs.state : 'Unknown'
  end

  def has_centers?
    self.errors.add(:centers, "- required field.") if self.centers.blank?
    self.errors.add(:centers, " should belong to one zone.") if !::Zone::all_centers_in_one_zone?(self.centers)
#    self.errors.add(:centers, " should belong to one sector.") if !::Sector::all_centers_in_one_sector?(self.centers)
  end

  def has_per_day_price?
    self.errors.add(:per_day_price, "required for commercial venue.") if self.commercial? && self.per_day_price.blank?
  end

  def has_commercial?
    self.errors.add(:commercial, "should be selected for venue with per day price.") if self.commercial.blank? && !self.per_day_price.blank?
  end

  def is_pcc_accounts?
    return true if self.current_user.is? :pcc_accounts, :for => :any, :center_id => self.center_ids
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def is_sector_coordinator?
    return true if self.current_user.is? :sector_coordinator, :for => :any, :center_id => self.center_ids
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
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

    return true if self.current_user.is? :venue_coordinator, :for => :any, :center_id => center_ids
    return false
  end

  def can_update?
    return true if self.current_user.is? :sector_coordinator, :for => :any, :center_id => self.center_ids
    return true if self.current_user.is? :pcc_accounts, :for => :any, :center_id => self.center_ids
    return false
  end

  def can_view_schedule?
    return true if self.current_user.is? :center_scheduler, :for => :any, :center_id => self.center_ids
    return true if self.current_user.is? :venue_coordinator, :for => :any, :center_id => self.center_ids
    return false
  end

  # HACK - to route the call through venue object from the UI.
  def can_create_schedule?
    venue_schedule = VenueSchedule.new
    venue_schedule.current_user = self.current_user
    return venue_schedule.can_create?(self.center_ids)
  end

  def friendly_name
    ("#%d %s" % [self.id, self.name])
  end


  def friendly_name_for_sms
    "Venue ##{self.id} #{self.name} (#{(self.centers.map {|c| c[:name]}).join(", ")})"
  end


  def url
    Rails.application.routes.url_helpers.venue_url(self)
  end

  def friendly_first_name_for_email
    "Venue ##{self.id}"
  end

  def friendly_second_name_for_email
    " #{self.name}"
  end

  def friendly_name_for_sms
    "Venue ##{self.id} #{self.name}"
  end


  rails_admin do
    visible do
      bindings[:controller].current_user.is?(:venue_coordinator)
    end
    list do
      field :name
      field :capacity
      field :commercial
      field :per_day_price
      field :centers
    end
    edit do
      field :current_user, :hidden do
        visible false
        default_value do
          bindings[:view]._current_user
        end
      end
      field :name
      field :centers do
        help 'Required. Type any character to search for center ...'
        inline_add false
        associated_collection_cache_all true  # REQUIRED if you want to SORT the list as below
        associated_collection_scope do
          # bindings[:object] & bindings[:controller] are available, but not in scope's block!
          accessible_centers = bindings[:controller].current_user.accessible_centers(:venue_coordinator)
          Proc.new { |scope|
            # scoping all Players currently, let's limit them to the team's league
            # Be sure to limit if there are a lot of Players and order them by position
            # scope = scope.where(:id => accessible_centers )
            scope = scope.where(:id => accessible_centers )
          }
        end
      end
      field :description
      field :address
      field :pin_code
      field :capacity
      field :contact_name
      field :contact_phone
      field :contact_mobile
      field :contact_email
      field :contact_address
      field :commercial
      field :payment_contact_name
      field :payment_contact_address
      field :payment_contact_mobile
      field :per_day_price do
        help "Required (for commerical venues)."
      end
    end

  end
end

