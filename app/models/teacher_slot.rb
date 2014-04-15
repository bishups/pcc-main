class TeacherSlot < ActiveRecord::Base
  attr_accessible :date, :slot, :status

  belongs_to :user

  validates :date, :presence => true
  validates :slot, :presence => true
  validates :status, :presence => true
  validates :user_id, :presence => true

#  validate :start_and_end_dates, :scheduleOverlapNotAllowed

  # Validator
  def start_and_end_dates
    if self.date
      errors.add(:date, "- Start date must be in the future") if self.date < Time.zone.now
    end
  end

end
