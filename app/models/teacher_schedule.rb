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
  include CommonFunctions

  has_many :activity_logs, :as => :model, :inverse_of => :model
  has_many :notification_logs, :as => :model, :inverse_of => :model

  # attr_accessible :title, :body
  attr_accessor :current_user

  belongs_to :timing
  belongs_to :teacher
  belongs_to :program
  has_and_belongs_to_many :centers, :join_table => "centers_teacher_schedules"
  belongs_to :program_type

  attr_accessor :comment_category
  attr_accessible :comment_category

  attr_accessible :start_date, :end_date, :state, :program_type_id, :program_type
  attr_accessible :timing, :timing_id, :teacher, :teacher_id, :program, :program_id, :centers, :center_ids
  belongs_to :blocked_by_user, :class_name => User
  belongs_to :last_updated_by_user, :class_name => User
  attr_accessible :last_update, :last_updated_at

  #validates :blocked_by_user_id, :presence => true

  #has_many :program_teacher_schedules

  validates :start_date, :end_date, :timing, :centers, :state, :presence => true
  validates_with TeacherScheduleValidator

  validate :teacher_enabled?

  STATE_AVAILABLE = 'Available'
  STATE_UNAVAILABLE = 'Not Available'
  STATE_AVAILABLE_EXPIRED = 'Available (Expired)'
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
      ts = self.deep_dup
      ts.end_date = start_date - 1.day
      # turning off validation when saving, since dates will overlap database record corresponding to self
      if !ts.save(:validate => false)
        errors[:start_date] << "Unable to split schedule, around start date"
      end
      self.start_date = start_date
    end

    if self.end_date > end_date
      ts = self.deep_dup
      ts.start_date = end_date + 1.day
      # turning off validation when saving, since dates will overlap database record corresponding to self
      if !ts.save(:validate => false)
        errors[:end_date] << "Unable to split schedule, around end date"
      end
      self.end_date = end_date
    end
  end

  def is_connected?
    ::ProgramTeacherSchedule::CONNECTED_STATES.include?(self.state)
  end

  def can_combine_consecutive_schedules?
    additional_days = 0
    if (STATE_PUBLISHED + [STATE_AVAILABLE_EXPIRED]).include?(state)
      ts = TeacherSchedule.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").where(['teacher_schedules.end_date = ? AND teacher_schedules.timing_id = ? AND teacher_schedules.state = ? AND teacher_schedules.teacher_id = ? AND centers_teacher_schedules.center_id IN (?)',
                                  start_date - 1.day, timing_id, state, teacher_id, center_ids]).first
      if ts
        additional_days += ts.no_of_days
      end

      ts = TeacherSchedule.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").where(['teacher_schedules.start_date = ? AND teacher_schedules.timing_id = ? AND teacher_schedules.state = ? AND teacher_schedules.teacher_id = ? AND centers_teacher_schedules.center_id IN (?)',
                                  end_date + 1.day, timing_id, state, teacher_id, center_ids]).first
      if ts
        additional_days += ts.no_of_days
      end
      additional_days
    end
  end


  def combine_consecutive_schedules!
    if (STATE_PUBLISHED+ [STATE_AVAILABLE_EXPIRED]).include?(state)
      ts = TeacherSchedule.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").where(['teacher_schedules.end_date = ? AND teacher_schedules.timing_id = ? AND teacher_schedules.state = ? AND teacher_schedules.teacher_id = ? AND centers_teacher_schedules.center_id IN (?)',
                                  start_date - 1.day, timing_id, state, teacher_id, center_ids]).readonly(false).first
      if ts
        self.start_date = ts.start_date
        ts.destroy
      end

      ts = TeacherSchedule.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").where(['teacher_schedules.start_date = ? AND teacher_schedules.timing_id = ? AND teacher_schedules.state = ? AND teacher_schedules.teacher_id = ? AND centers_teacher_schedules.center_id IN (?)',
                                  end_date + 1.day, timing_id, state, teacher_id, center_ids]).readonly(false).first
      if ts
        self.end_date = ts.end_date
        ts.destroy
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
    pts.current_user = self.current_user

    # verify when all the events can come
    if valid_states[event].include?(pts.state)
      self.comments = event
      pts.send(event)
      # also call update on the model
      pts.update(event) if pts.errors.empty?
    else
      # TODO - IMPORTANT - log that we are ignore the event and what state are we in presently
    end
    self.errors[:base] << pts.errors.full_messages unless pts.errors.empty?
  end


  def can_create?
    return true if self.current_user == self.teacher.user
    return false
  end

  def can_update?
    return true if self.current_user == self.teacher.user
    return false
  end

  # This is a hack - this needs to be in sync with can_view? of program_teacher_schedule
  # GOTCHA - make usre current user is initialized for self
  def can_view_schedule?
    return true if self.current_user.is? :center_scheduler, :center_id => self.program.center_id
    return true if self.current_user == self.teacher.user
    return false
  end


  def split_schedule_on_start_date!(start_date)
    if self.start_date < start_date
      ts = self.deep_dup
      # save the future day(s) schedule, after advancing start_date to today's date
      ts.start_date = start_date
      # TODO - check how to do error handling
      # turning off validation when saving, since dates will overlap database record corresponding to self
      if !ts.save(:validate => false)
        errors[:start_date] << "Unable to split schedule, around start date"
      end
      self.end_date = start_date - 1.day
    end
  end


  # this is a cron job, run through whenever gem
  # from the config/schedule.rb file
  def self.mark_as_expired
    # see if it can be combined with other schedules
    current_date = Time.zone.now.to_date
    teacher_schedules = TeacherSchedule.where('start_date < ? AND state IN (?)', current_date, ::TeacherSchedule::STATE_PUBLISHED)
    teacher_schedules.each { |ts|
      # split the current STATE_AVAILABLE schedule, in one day (previous_day) and future day(s) schedule
      ts.split_schedule_on_start_date!(current_date)
      # In case state was AVAILABLE, mark it as EXPIRED, else leave UNAVAILABLE as is
      ts.state = STATE_AVAILABLE_EXPIRED if ts.state == STATE_AVAILABLE
      ts.combine_consecutive_schedules! if ts.can_combine_consecutive_schedules?
      # TODO - check how to do error handling
      # turning off validation when saving, since dates are in past
      if !ts.save(:validate => false)
        self.errors[:base] << ts.errors.full_messages
      end
      # send notifications every x days - depending upon the program type that the teacher is enabled for
      every_x_days = Teacher.joins("JOIN program_types_teachers ON teachers.id = program_types_teachers.teacher_id").joins("JOIN program_types ON program_types.id = program_types_teachers.program_type_id").where("teachers.id IS ?", ts.teacher_id).minimum("program_types.no_of_days")
      if (ts.no_of_days % every_x_days == 0)
        ts.notify(STATE_AVAILABLE, STATE_AVAILABLE_EXPIRED, :any, ts.centers) if ts.state == STATE_AVAILABLE_EXPIRED
      end
    }
  end

  def deep_dup
    # from http://stackoverflow.com/questions/5976684/cloning-a-record-in-rails-is-it-possible-to-clone-associations-and-deep-copy
    ts = self.dup
    # turning off validation when saving, since dates will overlap database record corresponding to self
    if !ts.save(:validate => false)
      errors[:base] << "copy error"
    end
    ts.centers = self.centers
    ts
  end

  def friendly_name_for_email
    {
        :text => friendly_name_for_sms,
        :link => Rails.application.routes.url_helpers.teacher_teacher_schedule_url(self)
    }
  end

  def friendly_name_for_sms
    name = "Teacher Schedule ##{self.id} #{self.user.firstname} (#{self.start_date.strftime('%d %B')}-#{self.end_date.strftime('%d %B %Y')})"
  end

end
