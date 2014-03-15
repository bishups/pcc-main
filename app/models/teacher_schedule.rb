class TeacherSchedule < ActiveRecord::Base
  # attr_accessible :title, :body
  attr_accessible :start_date, :end_date, :slot

  belongs_to :user
  has_many :program_teacher_schedules

  validates :start_date, :presence => true
  validates :end_date, :presence => true
  validates :slot, :presence => true
  validates :user_id, :presence => true

  validates :start_date, :end_date, :overlap => {:scope => ['user_id', 'slot'] }
  validate :start_and_end_dates

  #validates_with TeacherScheduleValidator

  def teacher
    self.user
  end

  private

  # Validator
  def start_and_end_dates
    if self.start_date and self.end_date
      errors.add(:start_date, "cannot be in the past") if self.start_date < Time.now
      errors.add(:end_date, "cannot be less than start date") if self.start_date > self.end_date
      errors.add(:end_date, "cannot be less than 3 days after start date") if (self.end_date - self.start_date) < 2.days
    end
  end
end
