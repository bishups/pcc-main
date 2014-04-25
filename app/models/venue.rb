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
#  seats           :integer
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
  # attr_accessible :title, :body
  attr_accessor :current_user
  attr_accessible :name, :description, :address, :pin_code, :capacity, :seats, :contact_name, :contact_phone,
  :contact_mobile, :contact_email, :contact_address, :commercial, :payment_contact_name,
  :payment_contact_address,:payment_contact_mobile,:per_day_price

  has_and_belongs_to_many :centers
  attr_accessible :center_ids, :centers
  validate :has_centers?
  validate :has_per_day_price?
  validate :has_commercial?

  has_many :venue_schedules

  belongs_to :comment_type, :class_name => "Comment", :foreign_key => "comment_id"
  attr_accessible :comment_type

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

  state_machine :state, :initial => STATE_UNKNOWN do

    event EVENT_PROPOSE do
      transition STATE_UNKNOWN => STATE_PROPOSED
    end

    event EVENT_APPROVE do
      transition [STATE_PROPOSED, STATE_REJECTED] => STATE_APPROVED
    end

    after_transition any => STATE_APPROVED do |venue, transition|
      # TODO: check if paid venue or not
      if venue.free?
        venue.send(EVENT_POSSIBLE)
      else
        venue.send(EVENT_REQUEST_FINANCE_APPROVAL)
      end
    end

    event EVENT_REQUEST_FINANCE_APPROVAL do
      transition [STATE_APPROVED, STATE_INSUFFICIENT_INFO] => STATE_PENDING_FINANCE_APPROVAL
    end
    after_transition any => STATE_PENDING_FINANCE_APPROVAL, :do => :notify_finance

    event EVENT_FINANCE_APPROVAL do
      transition [STATE_PENDING_FINANCE_APPROVAL] => STATE_POSSIBLE
    end

    event EVENT_POSSIBLE do
      transition [STATE_APPROVED] => STATE_POSSIBLE
    end
    after_transition any => STATE_POSSIBLE, :do => :notify_all

    event EVENT_REJECT do
      transition [STATE_PROPOSED, STATE_POSSIBLE] => STATE_REJECTED
    end
    before_transition STATE_POSSIBLE => STATE_REJECTED, :do => :can_reject?

    event EVENT_INSUFFICIENT_INFO do
      transition STATE_PENDING_FINANCE_APPROVAL => STATE_INSUFFICIENT_INFO
    end

   end

  def initialize(*args)
    super(*args)
  end

  def blockable_programs
    # the list returned here is not a confirmed list, it is a tentative list which might fail validations later
    # TODO - writing the query for confirmed list is too db intensive for now, so skipping it
    Program.where('programs.center_id IN (?) AND programs.start_date > ? AND programs.state NOT IN (?)', self.center_ids, Time.zone.now, ::Program::FINAL_STATES)
  end

  def notify_finance
    # TODO - notify finance
  end

  def notify_all
    # TODO - notify the relevant people
  end

  def can_reject?
    if self.is_active?
      self.errors[:base] << "Cannot reject the venue, it has active schedules. Please close the schedules and try again."
      return false
    end
    true
  end

  def is_active?
    return false if !self.venue_schedules
    self.venue_schedules.each { |vs|
      return true if vs.is_active?
    }
    false
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
    self.errors.add(:centers, " should belong to one sector.") if !::Sector::all_centers_in_one_sector?(self.centers)
  end

  def has_per_day_price?
    self.errors.add(:per_day_price, "required for commercial venue.") if self.commercial? && self.per_day_price.blank?
  end

  def has_commercial?
    self.errors.add(:commercial, "should be selected for venue with per day price.") if self.commercial.blank? && !self.per_day_price.blank?
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

  # TODO - this is a hack, to route the call through venue object from the UI.
  def can_create_schedule?
    venue_schedule = VenueSchedule.new
    venue_schedule.current_user = self.current_user
    return venue_schedule.can_create?(self.center_ids)
  end

  def friendly_name
    ("%s" % [self.name]).parameterize
  end

  rails_admin do
    list do
      field :name
      field :capacity
      field :commercial
      field :per_day_price
      field :centers
    end
    edit do
      field :name
      field :centers do
        help 'Required. Type any character to search for center ...'
        inline_add false
      end
      field :description
      field :address
      field :pin_code
      field :capacity
      field :seats
      field :contact_name
      field :contact_phone
      field :contact_mobile
      field :contact_email
      field :contact_address
      field :commercial
      field :payment_contact_name
      field :payment_contact_address
      field :payment_contact_mobile
      field :per_day_price
    end

  end
end

