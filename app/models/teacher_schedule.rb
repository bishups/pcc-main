# == Schema Information
#
# Table name: teacher_schedules
#
#  id                      :integer          not null, primary key
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  state                   :string(255)
#  start_date              :date
#  end_date                :date
#  timing_id               :integer
#  program_id              :integer
#  teacher_id              :integer
#  center_id               :integer
#  blocked_by_user_id      :integer
#  last_updated_by_user_id :integer
#  comments                :text
#  feedback                :text
#  last_update             :string(255)
#  last_updated_at         :datetime
#  role                    :string(255)
#  timing_str              :string(255)
#

class TeacherSchedule < ActiveRecord::Base
  include CommonFunctions

  has_many :activity_logs, :as => :model, :inverse_of => :model
  has_many :notification_logs, :as => :model, :inverse_of => :model

  has_paper_trail

  # attr_accessible :title, :body
  attr_accessor :current_user

  belongs_to :timing
  belongs_to :teacher
  belongs_to :program
  has_and_belongs_to_many :centers, :join_table => "centers_teacher_schedules"
  belongs_to :program_type

  attr_accessor :comment_category
  attr_accessible :comment_category

  attr_accessible :start_date, :end_date, :state, :program_type_id, :program_type, :comments, :feedback
  attr_accessible :timing, :timing_id, :timing_str, :teacher, :teacher_id, :role, :program, :program_id, :centers, :center_ids
  belongs_to :blocked_by_user, :class_name => User
  belongs_to :last_updated_by_user, :class_name => User
  attr_accessible :last_update, :last_updated_at

  #validates :blocked_by_user_id, :presence => true

  #has_many :program_teacher_schedules

  validates :start_date, :end_date, :state, :presence => true
  validates :timing, :centers, :presence => true, :unless => :in_reserved_state?
  validates :centers, :presence => true, :if => :in_activity_state?
  validates :comments, :presence => true, :if => :in_reserved_state?
  validates_with TeacherScheduleValidator, :on => :create

  validate :teacher_enabled?

  # Unknown state is just used for logging
  STATE_UNKNOWN = 'Unknown'
  STATE_AVAILABLE = 'Available'
  STATE_UNAVAILABLE = 'Not Available'
  STATE_ACTIVITY = 'Activity'
  STATE_BREAK = 'Break'
  STATE_RESERVED = 'Reserved'
  STATE_TRAVEL = 'Travel'
  STATE_AVAILABLE_EXPIRED = 'Available (Expired)'
  STATE_PUBLISHED = [
      STATE_AVAILABLE, STATE_UNAVAILABLE
  ]

  RESERVED_STATES = [STATE_ACTIVITY, STATE_BREAK, STATE_RESERVED, STATE_TRAVEL]

  # This event is just for logging/ notification purposes
  EVENT_EXPIRED = "Expired"
  EVENT_PUBLISH = "Publish"
  EVENT_EDIT = "Edit"
  EVENT_DELETE = "Delete"
  EVENT_RESERVE = "Reserve"
  EVENT_ADD_COMMENT = "Add Comment"

  ROLE_MAIN_TEACHER = "Main Teacher"
  ROLE_CO_TEACHER = "Co-Teacher"
  ROLE_ORGANIZING_TEACHER = "Organizing Teacher"
  ROLE_HALL_TEACHER = "Hall Teacher"
  ROLE_INITIATION_TEACHER = "Initiation Teacher"
  TEACHER_ROLES = [ROLE_MAIN_TEACHER, ROLE_CO_TEACHER, ROLE_ORGANIZING_TEACHER, ROLE_HALL_TEACHER, ROLE_INITIATION_TEACHER]

  #validates_with TeacherScheduleValidator

  # given a teacher schedule (linked to a program), returns a relation with all overlapping teacher_schedule(s) (linked to programs) for the specific teacher and timing_id, not in specified states
  # --  ts.id = NULL, ts.timing, ts.teacher_id, ts.program
  scope :overlapping_blocks, lambda { |ts, states| joins(:program).merge(Program.all_overlapping_for_timing_id(ts.program, ts.timing_id)).
                                    where('(teacher_schedules.id != ? OR ? IS NULL) AND teacher_schedules.state NOT IN (?) AND teacher_schedules.teacher_id = ? AND teacher_schedules.timing_id = ?',
                                    ts.id, ts.id, states, ts.teacher_id, ts.timing_id) }

  # given a teacher schedule (linked to a program), returns a relation with other overlapping teacher_schedule(s) (linked to programs) for the specific teacher, not in specified states
  # where full day is over-lapping
  # --  ts.id = NULL, ts.timing, ts.teacher_id, ts.program
  scope :overlapping_full_day_blocks, lambda { |ts, full_day_date| joins(:program).merge(Program.overlapping(ts.program)).
                                            where('(teacher_schedules.id != ? OR ? IS NULL) AND teacher_schedules.teacher_id = ? AND (teacher_schedules.start_date <= ? AND teacher_schedules.end_date >= ?)',
                                            ts.id, ts.id, ts.teacher_id, full_day_date, full_day_date) }

  # given a teacher schedule (not linked to program), returns a relation with other overlapping teacher schedules(s) (linked to programs) for the specific teacher, not in specified states
  # -- ts.id = NULL, ts.teacher_id, ts.start_date, ts.end_date
  scope :overlapping_date_blocks, lambda { |ts, states| joins(:program).merge(Program.overlapping_date_time(ts.start_date, (ts.end_date.nil? ? ts.end_date: ts.end_date + 1.day - 1.minute))).where('(teacher_schedules.id != ? OR ? IS NULL) AND teacher_schedules.state NOT IN (?) AND teacher_schedules.teacher_id = ?', ts.id, ts.id, states, ts.teacher_id) }

  # given a teacher schedule, returns a relation with other overlapping teacher schedule(s) (not linked to program), for the specific teacher, in specified states
  # -- ts.id = NULL, ts.teacher_id
  scope :overlapping_reserves, lambda { |ts, start_date, end_date| where('teacher_schedules.program_id IS NULL AND (teacher_schedules.id != ? OR ? IS NULL) AND teacher_schedules.state IN (?) AND teacher_schedules.teacher_id = ? AND ((teacher_schedules.start_date BETWEEN ? AND ?) OR (teacher_schedules.end_date BETWEEN ? AND ?) OR  (teacher_schedules.start_date <= ? AND teacher_schedules.end_date >= ?))',
                                                   ts.id, ts.id, RESERVED_STATES, ts.teacher_id, start_date, end_date, start_date, end_date, start_date, end_date)}

  def schedule_overlaps?
    if self.program.nil?
      return true if TeacherSchedule.overlapping_reserves(self, self.start_date, self.end_date).count() > 0
      # HACK - STATE_UNKNOWN is just a place-holder for now. Ideally this will be states which denote a cancelled scheduled
      return true if TeacherSchedule.overlapping_date_blocks(self, [STATE_UNKNOWN]).count() > 0
    else
      return true if TeacherSchedule.overlapping_reserves(self, self.program.start_date.to_date, self.program.end_date.to_date).count() > 0
      # HACK - STATE_UNKNOWN is just a place-holder for now. Ideally this will be states which denote a cancelled scheduled
      return true if TeacherSchedule.overlapping_blocks(self, [STATE_UNKNOWN]).count() > 0
    end
    return false
  end

  after_create do |ts|
    if ts.program.nil?
      ts.log_last_activity(ts.current_user, STATE_UNKNOWN, ts.state, EVENT_PUBLISH)
    end
  end

  after_update  do |ts|
    if ts.program.nil?
      current_state = ts.state
      last_state = self.state_changed? ? changes[:state][0] : ts.state
      ts.log_last_activity(ts.current_user, last_state, current_state, EVENT_EDIT)
    end
  end

  before_destroy do |ts|
    if ts.program.nil?
      ts.log_last_activity(ts.current_user, ts.state, STATE_UNKNOWN, EVENT_DELETE)
    end
  end

  def in_reserved_state?
    RESERVED_STATES.include?(self.state)
  end

  def in_activity_state?
    self.state == STATE_ACTIVITY
  end

#  def teacher
#    self.teacher.user
#  end
  def teacher_enabled?
    self.errors.add("Not attached to zone. Please contact your co-ordinator.") if self.teacher.state == Teacher::STATE_UNATTACHED
  end

  def display_timings(role)
    return "Full Day" if self.in_reserved_state?
    program = self.program
    return self.timing_str if program.blank?

    # in residential, or custom session duration, teacher cannot be linked in different roles, to different timings
    return self.program.timing_str if program.residential? or program.custom_session_duration?

    # concatenate all the timing_str from all the schedule linked to the program for specified role
    timing_strs = TeacherSchedule.where("program_id = ? AND teacher_id = ? AND role IN (?)", program.id, self.teacher.id, role).pluck(:timing_str)
    timing_str = timing_strs.reject(&:blank?).join(", ")

=begin
    # adding full day information -- e.g, (3rd, 4th: Full Day)
    if program.has_full_day?
      full_day_str = program.program_donation.program_type.full_days.map{|d| "#{(self.start_date + (d-1).days).day.ordinalize}"}.join(", ")
      return "#{timing_str} (#{full_day_str}: Full Day)"
    else
      return timing_str
    end
=end
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

  def in_schedule?
    self.is_connected? or self.state == ::ProgramTeacherSchedule::STATE_BLOCK_REQUESTED
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
        ::Program::DROPPED => [::ProgramTeacherSchedule::STATE_BLOCK_REQUESTED],
        ::Program::ANNOUNCED => [::ProgramTeacherSchedule::STATE_BLOCKED],
        ::Program::STARTED => [::ProgramTeacherSchedule::STATE_ASSIGNED],
        ::Program::FINISHED => [::ProgramTeacherSchedule::STATE_IN_CLASS, ::ProgramTeacherSchedule::STATE_BLOCKED, ::ProgramTeacherSchedule::STATE_BLOCK_REQUESTED, ::ProgramTeacherSchedule::STATE_RELEASE_REQUESTED]
    }

    # first create the temporary object
    pts = ProgramTeacherSchedule.new
    pts.teacher_schedule = self
    pts.teacher_schedule_id = pts.teacher_schedule.id
    pts.id = pts.teacher_schedule_id # HACK - for logging pupose
    pts.state = pts.teacher_schedule.state
    pts.program_id = pts.teacher_schedule.program_id
    pts.program = Program.find(pts.teacher_schedule.program_id)
    pts.teacher_id = pts.teacher_schedule.teacher_id
    pts.teacher = Teacher.find(pts.teacher_schedule.teacher_id)
    pts.blocked_by_user_id = pts.teacher_schedule.blocked_by_user_id
    pts.timing_str = pts.teacher_schedule.timing_str
    pts.teacher_role = pts.teacher_schedule.role
    pts.current_user = User.current_user

    # verify when all the events can come
    if valid_states[event].include?(pts.state)
      self.comments = event
      pts.send(event)
      # also call update on the model
      pts.update(pts.teacher_role, event) if pts.errors.empty?
    else
      # TODO - IMPORTANT - log that we are ignore the event and what state are we in presently
    end
    self.errors[:base] << pts.errors.full_messages unless pts.errors.empty?
  end


  def can_create?
    center_ids = self.teacher.center_ids
    if self.teacher.full_time?
      # adding :any condition, in case teacher shared across zones
      return true if User.current_user.is? :zao, :for => :any, :center_id => center_ids
    else
      return true if User.current_user == self.teacher.user
    end
    # super_admin can create schedule on behalf of the teacher
    return true if User.current_user.is? :super_admin
    return false
  end

  def can_update?
    center_ids = self.center_ids
    if self.teacher.full_time?
      # can update (or delete) only if zao for all centers for which the schedule is published
      return true if User.current_user.is? :zao, :center_id => center_ids
    else
      return true if User.current_user == self.teacher.user
    end
    # super_admin can update schedule on behalf of the teacher
    return true if User.current_user.is? :super_admin
    return false
  end

  def can_delete?
    # for now, same as can_update?s
    self.can_update?
  end

  # This is a hack - this needs to be in sync with can_view? of program_teacher_schedule
  # GOTCHA - make current user is initialized for self
  def can_view_schedule?
    if self.program.nil?
      if self.teacher.full_time?
        return true if User.current_user.is? :zao, :for => :any, :center_id => self.teacher.center_ids
      else
        return true if User.current_user.is? :center_scheduler, :for => :any, :center_id => self.teacher.center_ids
      end
    else
      center_ids = [self.program.center_id.to_i]
      center_ids += self.teacher.primary_zones_center_ids if self.state == ::ProgramTeacherSchedule::STATE_BLOCK_REQUESTED
      if self.teacher.full_time?
        return true if User.current_user.is? :zao, :for => :any, :center_id => center_ids
      else
        return true if User.current_user.is? :center_scheduler, :for => :any, :center_id => center_ids
      end
    end
    return true if User.current_user == self.teacher.user
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
      # send notifications every x days for a part-time teacher - depending upon the program type that the teacher is enabled for as main teacher
      unless ts.teacher.full_time?
        every_x_days = 365
        ts.teacher.roles.each { |role|
          program_types_teachers_str = ::Teacher::PROGRAM_TYPES_TABLES[role]
          days = Teacher.joins("JOIN #{program_types_teachers_str} ON teachers.id = #{program_types_teachers_str}.teacher_id").joins("JOIN program_types ON program_types.id = #{program_types_teachers_str}.program_type_id").where("teachers.id = ?", ts.teacher_id).minimum("program_types.no_of_days")
          every_x_days = [every_x_days, days].min
        }
        if (ts.no_of_days % every_x_days.to_i == 0)
          ts.notify(STATE_AVAILABLE, STATE_AVAILABLE_EXPIRED, EVENT_EXPIRED, ts.centers, ts.teacher) if ts.state == STATE_AVAILABLE_EXPIRED
        end
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

  def delete_reserve!
    # delete only the future part of the reserve
    end_date = Time.zone.now.to_date - 1.minute

    # if there is no past part - delete the object itself, else update the dates and save
    if end_date.to_date < self.start_date.to_date
      # notify the availability of future part
      self.store_last_update!(User.current_user, self.state, ::TeacherSchedule::STATE_AVAILABLE, EVENT_DELETE)
      self.notify(self.state, ::TeacherSchedule::STATE_AVAILABLE, EVENT_DELETE, self.teacher.centers, self.teacher)
      self.destroy
    else
      # create a dummy to log and notify
      ts = self.deep_dup
      ts.start_date = Time.zone.now
      # notify the availability of future part
      ts.store_last_update!(ts.current_user, ts.state, ::TeacherSchedule::STATE_AVAILABLE, EVENT_DELETE)
      self.notify(ts.state, ::TeacherSchedule::STATE_AVAILABLE, EVENT_DELETE, self.teacher.centers, self.teacher)
      # save the past part
      self.end_date = end_date
      self.save
    end
  end

  def url
    self.program.nil? ? Rails.application.routes.url_helpers.teacher_teacher_schedules_url(self.teacher)
    : Rails.application.routes.url_helpers.program_teacher_schedule_url(self)
  end

  def friendly_first_name_for_email
    self.program.nil? ? "Teacher Schedule ##{self.id}"
    :  "Program-Teacher Schedule ##{self.id}"
  end

  def friendly_second_name_for_email
    if self.program.nil?
      if self.timing.nil?
        " for #{self.teacher.user.fullname}, (#{self.start_date.strftime('%d %B')}-#{self.end_date.strftime('%d %B %Y')}) "
      else
        " for #{self.teacher.user.fullname}, #{self.timing.name}(#{self.start_date.strftime('%d %B')}-#{self.end_date.strftime('%d %B %Y')}) "
      end
    else
      " for Program ##{self.program.id} #{self.program.name} and Teacher ##{self.teacher.id} #{self.teacher.user.fullname}"
    end
  end

  def friendly_name_for_sms
    self.program.nil? ? "Teacher Schedule ##{self.id} for #{self.teacher.user.firstname}"
    : "Program-Teacher Schedule ##{self.id} for #{self.teacher.user.firstname}"
  end

end
