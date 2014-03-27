class TeacherSlot < ActiveRecord::Base
  attr_accessible :date, :slot, :status

  belongs_to :user

  validates :date, :presence => true
  validates :slot, :presence => true
  validates :status, :presence => true
  validates :user_id, :presence => true

  validate :start_and_end_dates, :scheduleOverlapNotAllowed

  # Validator
  def start_and_end_dates
    if self.start_date and self.end_date
      errors.add(:start_date, "must be in the future") if self.start_date < Time.now
      errors.add(:end_date, "cannot be before start date") if self.start_date > self.end_date
    end
  end

end
