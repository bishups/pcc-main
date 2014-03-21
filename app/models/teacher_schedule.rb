# == Schema Information
#
# Table name: teacher_schedules
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  slot       :string(255)
#  start_date :datetime
#  end_date   :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TeacherSchedule < ActiveRecord::Base
  # attr_accessible :title, :body
  attr_accessible :start_date, :end_date, :slot, :state

  belongs_to :user
  has_many :program_teacher_schedules

  validates :start_date, :presence => true
  validates :end_date, :presence => true
  validates :slot, :presence => true
  validates :user_id, :presence => true

  # validates :start_date, :end_date, :overlap => {:scope => ['user_id', 'slot'] }
  validate :start_and_end_dates, :scheduleOverlapNotAllowed

  #validates_with TeacherScheduleValidator

  def teacher
    self.user
  end

  private

  # Validator
  def start_and_end_dates
    if self.start_date and self.end_date
      errors.add(:start_date, "must be in the future") if self.start_date < Time.now
      errors.add(:end_date, "cannot be less than start date") if self.start_date > self.end_date
#      errors.add(:end_date, "cannot be less than 2 days after start date") if (self.end_date - self.start_date) < 2.days
    end
  end

  def scheduleOverlapNotAllowed
    # teacher schedule should not overlap with any existing schedule
    # By default state is 'unknown'
    # A teacher can change it from 'unknown' to 'available' or 'notAvailable'
    if (id == nil)
    if (slot != ::Ontology::Teacher::SLOT_FULL_DAY)
      if ::TeacherSchedule.where(['start_date >= ? AND start_date <= ? AND slot = ? AND user_id = ?', 
        start_date, end_date, slot, user_id]).count() > 0
        errors[:end_date] << "overlaps with existing schedule."
      elsif ::TeacherSchedule.where(['end_date >= ? AND end_date <= ? AND slot = ? AND user_id = ?', 
        start_date, end_date, slot, user_id]).count() > 0
        errors[:end_date] << "overlaps with existing schedule."
      elsif ::TeacherSchedule.where(['start_date >= ? AND start_date <= ? AND slot = ? AND user_id = ?', 
        start_date, end_date, ::Ontology::Teacher::SLOT_FULL_DAY, user_id]).count() > 0
        errors[:start_date] << "overlaps with existing schedule."
      elsif ::TeacherSchedule.where(['end_date >= ? AND end_date <= ? AND slot = ? AND user_id = ?', 
        start_date, end_date, ::Ontology::Teacher::SLOT_FULL_DAY, user_id]).count() > 0
        errors[:end_date] << "overlaps with existing schedule."
      end
    else 
      if ::TeacherSchedule.where(['start_date >= ? AND start_date <= ? AND user_id = ?', 
        start_date, end_date, user_id]).count() > 0
        errors[:end_date] << "overlaps with existing schedule."
      elsif ::TeacherSchedule.where(['end_date >= ? AND end_date <= ? AND user_id = ?', 
        start_date, end_date, user_id]).count() > 0
        errors[:end_date] << "overlaps with existing schedule."
      end
    end
  else 
    if (slot != ::Ontology::Teacher::SLOT_FULL_DAY)
      if ::TeacherSchedule.where(['start_date >= ? AND start_date <= ? AND slot = ? AND user_id = ? AND id != ?', 
        start_date, end_date, slot, user_id, id]).count() > 0
        errors[:end_date] << "overlaps with existing schedule."
      elsif ::TeacherSchedule.where(['end_date >= ? AND end_date <= ? AND slot = ? AND user_id = ? AND id != ?', 
        start_date, end_date, slot, user_id, id]).count() > 0
        errors[:end_date] << "overlaps with existing schedule."
      elsif ::TeacherSchedule.where(['start_date >= ? AND start_date <= ? AND slot = ? AND user_id = ? AND id != ?', 
        start_date, end_date, ::Ontology::Teacher::SLOT_FULL_DAY, user_id, id]).count() > 0
        errors[:start_date] << "overlaps with existing schedule."
      elsif ::TeacherSchedule.where(['end_date >= ? AND end_date <= ? AND slot = ? AND user_id = ? AND id != ?', 
        start_date, end_date, ::Ontology::Teacher::SLOT_FULL_DAY, user_id, id]).count() > 0
        errors[:end_date] << "overlaps with existing schedule."
      end
    else 
      if ::TeacherSchedule.where(['start_date >= ? AND start_date <= ? AND user_id = ? AND id != ?', 
        start_date, end_date, user_id, id]).count() > 0
        errors[:end_date] << "overlaps with existing schedule."
      elsif ::TeacherSchedule.where(['end_date >= ? AND end_date <= ? AND user_id = ? AND id != ?', 
        start_date, end_date, user_id, id]).count() > 0
        errors[:end_date] << "overlaps with existing schedule."
      end
    end
  end
  end

end
