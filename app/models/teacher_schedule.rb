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
  belongs_to :blocked_by_user, :class_name => User
  #validates :blocked_by_user_id, :presence => true

  #has_many :program_teacher_schedules

  validates :start_date, :end_date, :timing_id, :center_id, :state, :presence => true

  # validates :start_date, :end_date, :overlap => {:scope => ['user_id', 'slot'] }
  validate :start_and_end_dates, :scheduleOverlapNotAllowed
  validate :teacher_enabled?

  STATE_AVAILABLE = 'Available'
  STATE_UNAVAILABLE = 'Not Available'
  STATE_PUBLISHED = [
      STATE_AVAILABLE, STATE_UNAVAILABLE
  ]

  #validates_with TeacherScheduleValidator

#  def teacher
#    self.teacher.user
#  end
  def teacher_enabled?
    self.errors.add("Not attached to zone. Please contact your co-ordinator.") if self.teacher.state == Teacher::STATE_UNATTACHED
    self.errors.add("Not enabled to publish schedule. Please contact your co-ordinator.") if self.teacher.state == Teacher::STATE_UNFIT
  end

  def split_schedule!(start_date, end_date)
    if self.start_date < start_date
      ts = self.dup
      ts.end_date = start_date - 1.day
      if !ts.save(:validate => false)
        errors[:start_date] << "Unable to split schedule, around start date"
      end
      self.start_date = start_date
    end

    if self.end_date > end_date
      ts = self.dup
      ts.start_date = end_date + 1.day
      if !ts.save(:validate => false)
        errors[:end_date] << "Unable to split schedule, around end date"
      end
      self.end_date = end_date
    end
  end

  def is_connected?
    ::ProgramTeacherSchedule::CONNECTED_STATES.include?(self.state)
  end

  def combine_consecutive_schedules?
    additional_days = 0
    if (::TeacherSchedule::STATE_PUBLISHED).include?(state)
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
    if (::TeacherSchedule::STATE_PUBLISHED).include?(state)
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


  def on_program_event(event)
    valid_states = {
            ::Program::CANCELLED => [::ProgramTeacherSchedule::STATE_ASSIGNED],
            ::Program::DROPPED => [::ProgramTeacherSchedule::STATE_BLOCKED],
            ::Program::ANNOUNCED => [::ProgramTeacherSchedule::STATE_BLOCKED],
            ::Program::STARTED => [::ProgramTeacherSchedule::STATE_ASSIGNED],
            ::Program::FINISHED => [::ProgramTeacherSchedule::STATE_IN_CLASS],

    }

    # first create the temporary object
    pts = ProgramTeacherSchedule.new
    pts.teacher_schedule = self
    pts.teacher_schedule_id = pts.teacher_schedule.id
    pts.state = pts.teacher_schedule.state
    pts.program_id = pts.teacher_schedule.program_id
    pts.program = Program.find(pts.teacher_schedule.program_id)
    pts.teacher_id = pts.teacher_schedule.teacher_id
    pts.teacher = Teacher.find(pts.teacher_schedule.teacher_id)
    pts.blocked_by_user_id = pts.teacher_schedule.blocked_by_user_id


    # verify when all the events can come
    if valid_states[event].include?(pts.state)
      pts.send(event)
      # also call update on the model
      pts.update if pts.errors.empty?
    else
      # TODO - IMPORTANT - log that we are ignore the event and what state are we in presently
    end
    self.errors[:base] << pts.errors.full_messages unless pts.errors.empty?
  end

    private

  # Validator
  def start_and_end_dates
    if self.start_date and self.end_date
      errors.add(:start_date, "must be in the future") if self.start_date < Time.zone.now.to_date
      errors.add(:end_date, "cannot be less than start date") if self.start_date > self.end_date
#      errors.add(:end_date, "cannot be less than 2 days after start date") if (self.end_date - self.start_date) < 2.days
    end
  end

  def scheduleOverlapNotAllowed
    # teacher schedule should not overlap with any existing schedule
    ts = TeacherSchedule.where(['(start_date BETWEEN ? AND ?) AND timing_id = ? AND teacher_id = ?',
                                self.start_date, self.end_date, self.timing_id, self.teacher_id]).to_a
    if !ts.empty? && (ts.count > 1 || ts[0].id != self.id)
      errors[:start_date] << " timing overlaps with existing schedule."
      return
    end

    ts = TeacherSchedule.where(['(end_date BETWEEN ? AND ?) AND timing_id = ? AND teacher_id = ?',
                                self.start_date, self.end_date, self.timing_id, self.teacher_id]).to_a
    if !ts.empty? && (ts.count > 1 || ts[0].id != self.id)
        errors[:end_date] << " timing overlaps with existing schedule."
        return
    end

    ts = TeacherSchedule.where(['start_date <= ? AND end_date >= ? AND timing_id = ? AND teacher_id = ?',
                                self.start_date, self.end_date, self.timing_id, self.teacher_id]).to_a
    if !ts.empty? && (ts.count > 1 || ts[0].id != self.id)
       errors[:start_date] << " timing overlaps with existing schedule."
       return
    end
  end

end
