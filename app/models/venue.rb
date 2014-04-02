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
  attr_accessible :name, :description, :address, :pin_code, :capacity, :seats, :contact_name, :contact_phone,
  :contact_mobile, :contact_email, :contact_address, :commercial, :payment_contact_name,
  :payment_contact_address,:payment_contact_mobile,:per_day_price

  has_and_belongs_to_many :centers
  attr_accessible :center_ids, :centers
  validate :has_centers?
  validate :has_per_day_price?
  validate :has_commercial?

  has_many :venue_schedules

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



  STATE_PROPOSED  = :proposed
  STATE_APPROVED  = :approved
  STATE_REJECTED  = :rejected
  STATE_POSSIBLE  = :possible
  STATE_PENDING_FINANCE_APPROVAL = :pending_finance_approval
  STATE_INSUFFICIENT_INFO = :insufficient_info
  STATE_PUBLISHED = :published

  PROCESSABLE_EVENTS = [
    :approve, :reject, :publish, :possible, :insufficient_info, :finance_approval
  ]

  state_machine :state, :initial => STATE_PROPOSED do
    event :approve do
      transition [STATE_PROPOSED, STATE_REJECTED] => STATE_APPROVED
    end

    after_transition any => STATE_APPROVED do |venue, transition|
      # TODO: check if paid venue or not
      if venue.paid?
        venue.finance_approval()
      else
        venue.possible()
      end
    end

    event :finance_approval do
      transition [STATE_APPROVED, STATE_INSUFFICIENT_INFO] => STATE_PENDING_FINANCE_APPROVAL
    end

    event :possible do
      transition [STATE_APPROVED, STATE_PENDING_FINANCE_APPROVAL] => STATE_POSSIBLE
    end

    event :reject do
      transition [STATE_PROPOSED, STATE_POSSIBLE] => STATE_REJECTED
    end

    event :publish do
      transition [STATE_POSSIBLE] => STATE_PUBLISHED
    end

    event :insufficient_info do
      transition STATE_PENDING_FINANCE_APPROVAL => STATE_INSUFFICIENT_INFO
    end

   end

  def initialize(*args)
    super(*args)
  end

  def blockable_programs
    Program.where('center_id = ? AND start_date > ?', self.center_id, Time.now)
  end

  def paid?
    self.per_day_price.to_i > 0
  end

  def published?
    self.state.to_sym == STATE_PUBLISHED
  end

  def current_schedule
    self.venue_schedules.where('start_date < ? AND end_date > ?', Time.now, Time.now).first()
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

