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

  belongs_to :timing
  belongs_to :teacher
  belongs_to :program
  belongs_to :center

  attr_accessible :start_date, :end_date, :state
  attr_accessible :timing, :timing_id, :teacher, :teacher_id, :program, :program_id, :center, :center_id

  #has_many :program_teacher_schedules

  validates :start_date, :end_date, :timing_id, :center_id, :state, :presence => true

  # validates :start_date, :end_date, :overlap => {:scope => ['user_id', 'slot'] }
  validate :start_and_end_dates, :scheduleOverlapNotAllowed
  validate :teacher_enabled?

  #validates_with TeacherScheduleValidator

#  def teacher
#    self.teacher.user
#  end
  def teacher_enabled?
    self.errors.add("Not attached to zone. Please contact your co-ordinator.") if self.teacher.zone.blank?
    self.errors.add("Not enabled to publish schedule. Please contact your co-ordinator.") if !self.teacher.unfit.blank? && self.teacher.unfit?
  end

  def split_schedule(start_date, end_date)
    if self.start_date < start_date
      ts = self.dup
      ts.end_date = start_date - 1.day
      if !ts.save #(validate: false)
        errors[:start_date] << "Unable to split schedule, around start date"
      end
      self.start_date = start_date
    end

    if self.end_date > end_date
      ts = self.dup
      ts.start_date = end_date + 1.day
      if !ts.save #(validate: false)
        errors[:end_date] << "Unable to split schedule, around end date"
      end
      self.end_date = end_date
    end
  end


  def combine_consecutive_schedules?
    additional_days = 0
    if (state == ::Ontology::Teacher::STATE_AVAILABLE || state == ::Ontology::Teacher::STATE_UNAVAILABLE)
      ts = TeacherSchedule.where(['end_date = ? AND timing_id = ? AND state = ? AND teacher_id = ? AND center_id = ?',
                                  start_date - 1.day, timing_id, state, teacher_id, center_id]).first
      if ts
        additional_days += ts.no_of_days
      end

      ts = TeacherSchedule.where(['start_date = ? AND timing_id = ? AND state = ? AND teacher_id = ? AND center_id = ?',
                                  end_date + 1.day, timing_id, state, teacher_id, center_id]).first
      if ts
        additional_days += ts.no_of_days
      end
      additional_days
    end
  end


  def combine_consecutive_schedules()
    if (state == ::Ontology::Teacher::STATE_AVAILABLE || state == ::Ontology::Teacher::STATE_UNAVAILABLE)
      ts = TeacherSchedule.where(['end_date = ? AND timing_id = ? AND state = ? AND teacher_id = ? AND center_id = ?',
                                  start_date - 1.day, timing_id, state, teacher_id, center_id]).first
      if ts
        self.start_date = ts.start_date
        ts.delete
      end

      ts = TeacherSchedule.where(['start_date = ? AND timing_id = ? AND state = ? AND teacher_id = ? AND center_id = ?',
                                  end_date + 1.day, timing_id, state, teacher_id, center_id]).first
      if ts
        self.end_date = ts.end_date
        ts.delete
      end
    end
  end


  def no_of_days
    end_date.mjd - start_date.mjd + 1
  end



    private

  # Validator
  def start_and_end_dates
    if self.start_date and self.end_date
      errors.add(:start_date, "must be in the future") if self.start_date < Time.now.to_date
      errors.add(:end_date, "cannot be less than start date") if self.start_date > self.end_date
#      errors.add(:end_date, "cannot be less than 2 days after start date") if (self.end_date - self.start_date) < 2.days
    end
  end

  def scheduleOverlapNotAllowed
    # teacher schedule should not overlap with any existing schedule
    ts = TeacherSchedule.where(['(start_date BETWEEN ? AND ?) AND timing_id = ? AND teacher_id = ?',
                                start_date, end_date, timing_id, teacher_id]).to_a
    if !ts.empty? && (ts.count > 1 || ts[0].id != self.id)
      errors[:start_date] << "start date overlaps with existing schedule."
    end

    ts = TeacherSchedule.where(['(end_date BETWEEN ? AND ?) AND timing_id = ? AND teacher_id = ?',
                                 start_date, end_date, timing_id, teacher_id]).to_a
    if !ts.empty? && (ts.count > 1 || ts[0].id != self.id)
        errors[:end_date] << "overlaps with existing schedule."
    end
  end

end
