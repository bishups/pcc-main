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
  attr_accessible :name
  attr_accessible :description
  attr_accessible :address
  attr_accessible :pin_code
  attr_accessible :capacity
  attr_accessible :seats
  attr_accessible :contact_name
  attr_accessible :contact_phone
  attr_accessible :contact_mobile
  attr_accessible :contact_email
  attr_accessible :contact_address
  attr_accessible :zone_id
  attr_accessible :center_id

  belongs_to :center
  has_many :venue_schedules

  validates_presence_of :zone_id
  validates_presence_of :center_id
  validates_uniqueness_of :name, :scope => [:zone_id, :center_id]

  STATE_PROPOSED  = :proposed
  STATE_APPROVED  = :approved
  STATE_REJECTED  = :rejected
  STATE_POSSIBLE  = :possible
  STATE_PENDING_FINANCE_APPROVAL = :pending_finance_approval
  STATE_INSUFFICIENT_INFO = :insufficient_info
  STATE_PUBLISHED = :published

  PROCESSABLE_EVENTS = [
    :approve, :reject, :publish, :insufficient_info
  ]

  state_machine :state, :initial => STATE_PROPOSED do
    event :approve do
      transition [STATE_PROPOSED, STATE_INSUFFICIENT_INFO, STATE_REJECTED] => STATE_APPROVED
    end

    after_transition any => STATE_APPROVED do |transition|
      # TODO: check if paid venue or not
      if self.paid?
        self.finance_approval()
      else
        self.possible()
      end
    end

    event :finance_approval do
      transition STATE_APPROVED => STATE_PENDING_FINANCE_APPROVAL
    end

    event :possible do
      transition [STATE_APPROVED, STATE_PENDING_FINANCE_APPROVAL] => STATE_POSSIBLE
    end

    event :reject do
      transition [STATE_PROPOSED, STATE_PUBLISHED] => STATE_REJECTED
    end

    event :publish do
      transition [STATE_APPROVED, STATE_PENDING_FINANCE_APPROVAL] => STATE_PUBLISHED
    end

    event :insufficient_info do
      transition STATE_PENDING_FINANCE_APPROVAL => STATE_INSUFFICIENT_INFO
    end
  end

  def initialize(*args)
    super(args)
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

end
