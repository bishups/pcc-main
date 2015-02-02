# == Schema Information
#
# Table name: program_teacher_schedules
#
#  id                  :integer          not null, primary key
#  program_id          :integer
#  user_id             :integer
#  teacher_schedule_id :integer
#  created_by_user_id  :integer
#  start_date          :integer
#  end_date            :integer
#  slot                :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

=begin
class ProgramTeacherSchedule < ActiveRecord::Base
  # attr_accessible :title, :body
  attr_accessible :program_id
  attr_accessible :teacher_schedule_id
  #attr_accessible :user_id

  belongs_to :user
  belongs_to :program
  belongs_to :teacher_schedule

  validates :program_id, :presence => true
  validates :teacher_schedule_id, :presence => true
  #validates :user_id, :presence => true
  validates :created_by_user_id, :presence => true
  validates_uniqueness_of :program_id, :scope => [:teacher_schedule_id]
  validates :start_date, :end_date, :overlap => [:teacher_schedule_id, :slot]

  before_create :copy_program_attributes!

  private

  def copy_program_attributes!
    self.user_id = self.teacher_schedule.user_id
    self.start_date = self.program.start_date
    self.end_date = self.program.end_date
    self.slot = self.program.slot
  end
end
=end

class ProgramTeacherSchedule < ActiveRecord::Base
  include CommonFunctions
  # needed for using form_for
  #extend ActiveModel::Naming
  #include ActiveModel::AttributeMethods

  #composed_of :program, mapping: %w(program_id id)
  #composed_of :teacher_schedule, mapping: [ %w(teacher_id teacher_id), %w(schedule_id id), %w(reserving_user_id reserving_user_id) ]

  attr_accessor :teacher_id, :teacher, :blocked_by_user_id, :blocked_by_user, :program, :program_id, :deleted_program, :deleted_program_id, :teacher_schedule, :teacher_schedule_id, :comments, :feedback, :comment_category
  attr_accessor :current_user, :state, :teacher_role, :timing_ids, :timings, :timing_str

  # HACK - for logging
  attr_accessor :id
  # attr_accessible :program, :teacher_id, :reserving_user_id
  # validates :program_id, :teacher_id, :reserving_user_id, :presence => true

  belongs_to :program
  #STATE_UNKNOWN  = :unknown
  #STATE_UNKNOWN             = 'Unknown'
  STATE_BLOCK_REQUESTED     = 'Block Requested'
  STATE_BLOCKED             = 'Blocked'
  STATE_ASSIGNED            = 'Assigned'
  STATE_RELEASE_REQUESTED   = 'Release Requested'
  STATE_IN_CLASS            = 'In Class'
  STATE_COMPLETED_CLASS     = 'Completed Class'

  CONNECTED_STATES = [STATE_BLOCKED, STATE_RELEASE_REQUESTED, STATE_ASSIGNED, STATE_IN_CLASS]
  FINAL_STATES = [STATE_COMPLETED_CLASS]


  # Events
  EVENT_BLOCK              = 'Block'
  EVENT_REQUEST_BLOCK      = 'Request Block'
  EVENT_CANCEL             = 'Cancel'
  EVENT_REJECT             = 'Reject'
  EVENT_APPROVE            = 'Approve'
  EVENT_REQUEST_RELEASE    = 'Request Release'
  EVENT_RELEASE            = 'Release'
  # Unknown Event, used only for logging
  EVENT_UNKNOWN = 'Unknown'

  PROCESSABLE_EVENTS = [
      EVENT_CANCEL, EVENT_REJECT, EVENT_APPROVE, EVENT_REQUEST_RELEASE, EVENT_RELEASE
  ]

  EVENTS_WITH_COMMENTS = [EVENT_CANCEL, EVENT_REJECT, EVENT_RELEASE, EVENT_REQUEST_RELEASE]
  EVENTS_WITH_FEEDBACK = []


  state_machine :state, :initial => ::TeacherSchedule::STATE_AVAILABLE do

    event EVENT_BLOCK do
      transition ::TeacherSchedule::STATE_AVAILABLE => STATE_BLOCKED, :if => lambda {|t| t.can_create?}
    end
    before_transition ::TeacherSchedule::STATE_AVAILABLE => STATE_BLOCKED, :do => :can_block?
    after_transition ::TeacherSchedule::STATE_AVAILABLE => STATE_BLOCKED, :do => :on_block

    event EVENT_REQUEST_BLOCK do
      transition ::TeacherSchedule::STATE_AVAILABLE => STATE_BLOCK_REQUESTED, :if => lambda {|t| t.can_create_block_request?}
    end
    before_transition ::TeacherSchedule::STATE_AVAILABLE => STATE_BLOCK_REQUESTED, :do => :can_request_block?

    event EVENT_APPROVE do
      transition STATE_BLOCK_REQUESTED => STATE_BLOCKED, :if => lambda {|t| t.can_approve_block?}
    end
    before_transition STATE_BLOCK_REQUESTED => STATE_BLOCKED, :do => :can_approve?
    after_transition STATE_BLOCK_REQUESTED => STATE_BLOCKED, :do => :on_block

    event EVENT_REJECT do
      transition STATE_BLOCK_REQUESTED => ::TeacherSchedule::STATE_AVAILABLE, :if => lambda {|pts| pts.can_approve_block? }
    end

    event ::Program::DROPPED do
      transition [STATE_BLOCK_REQUESTED, STATE_BLOCKED] => ::TeacherSchedule::STATE_AVAILABLE
    end

    event EVENT_CANCEL do
      transition STATE_BLOCKED => ::TeacherSchedule::STATE_AVAILABLE, :if => lambda {|pts| pts.is_center_scheduler? or pts.is_zao? }
      transition STATE_BLOCK_REQUESTED => ::TeacherSchedule::STATE_AVAILABLE, :if => lambda {|pts| pts.can_create_block_request? }
    end
    before_transition STATE_BLOCKED => ::TeacherSchedule::STATE_AVAILABLE do |pts, transition|
      pts.can_unblock? unless transition.event == ::Program::DROPPED
    end
    before_transition STATE_BLOCK_REQUESTED => ::TeacherSchedule::STATE_AVAILABLE do |pts, transition|
      if transition.event == EVENT_CANCEL
        pts.can_request_block?
      elsif transition.event == EVENT_REJECT
        pts.can_approve?
      end
      # No check in case of event being ::Program::DROPPED
    end

    event EVENT_RELEASE do
      transition STATE_ASSIGNED => ::TeacherSchedule::STATE_UNAVAILABLE, :if => lambda {|pts| pts.is_sector_coordinator? || pts.is_zao?}
      transition STATE_RELEASE_REQUESTED => ::TeacherSchedule::STATE_UNAVAILABLE, :if => lambda {|pts| pts.is_sector_coordinator? || pts.is_zao? }
    end
    before_transition STATE_ASSIGNED => ::TeacherSchedule::STATE_UNAVAILABLE, :do => :can_mark_assign_to_unavailable?
    before_transition STATE_RELEASE_REQUESTED => ::TeacherSchedule::STATE_UNAVAILABLE, :do => :can_approve_release?

    event EVENT_REQUEST_RELEASE do
      transition [STATE_BLOCKED, STATE_ASSIGNED] => STATE_RELEASE_REQUESTED, :if => lambda {|pts| pts.is_teacher? }
    end
    before_transition any => STATE_RELEASE_REQUESTED, :do => :is_teacher?

    event ::Program::CANCELLED do
      transition STATE_ASSIGNED => ::TeacherSchedule::STATE_AVAILABLE
    end

    event ::Program::ANNOUNCED do
      transition [STATE_BLOCKED, STATE_RELEASE_REQUESTED] => STATE_ASSIGNED
    end
    after_transition [STATE_BLOCKED, STATE_RELEASE_REQUESTED] => STATE_ASSIGNED, :do => :if_program_started!

    event ::Program::STARTED do
      transition STATE_ASSIGNED => STATE_IN_CLASS
    end

    event ::Program::FINISHED do
      transition STATE_IN_CLASS => STATE_COMPLETED_CLASS
      transition [STATE_BLOCK_REQUESTED, STATE_BLOCKED, STATE_RELEASE_REQUESTED] => ::TeacherSchedule::STATE_AVAILABLE_EXPIRED
    end

    before_transition any => any do |object, transition|
      # Don't return here, else LocalJumpError will occur
      if EVENTS_WITH_COMMENTS.include?(transition.event) && !object.has_comments?
        false
      elsif EVENTS_WITH_FEEDBACK.include?(transition.event) && !object.has_feedback?
        false
      else
        true
      end
    end

    after_transition any => any do |object, transition|
      # NOTE: the last_update is handled differently in this case --
      # it needs to be stored with each of the linked teacher_schedules

      # HACK - In case the program reference was removed on cancellation of block
      center = object.program.nil? ? object.deleted_program.center : object.program.center
      object.notify(transition.from, transition.to, transition.event, center, object.teacher)
    end

  end


  def can_block?
    return true if self.can_create?
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def can_approve?
    return true if self.can_approve_block?
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def can_request_block?
    return true if self.can_create_block_request?
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def on_block
    self.if_program_announced!
  end

  def if_program_announced!
    if self.program.is_announced? && self.program.is_active?
      self.send(::Program::ANNOUNCED)
      #
      # *************************************************
      # Update the timing_str for all teacher schedule(s) for the teacher, linked to the program
      # (IMPORTANT NOTE - the logic here should be in sync with before_announce method)
      # *************************************************
      #
      # timing_str <-- used internally for displaying timings
      #
      # -----------------
      # After Announcing
      # -----------------
      # for Uyir Nokkam e.g, --
      # "9:30am - 10:30am, 9:30am - 10:30am, 9:30am - 10:30am, 9:30am - 10:30am"
      # for IE e.g, --
      # "(Intro) 6:30am - 9:30am, 6:00pm - 9:00pm; (Session) 6:30am - 9:30am, 10:00am - 1:00pm, 6:00pm - 9:00pm"
      # for BSP e.g, --
      # "Starts on 2nd at 5:00pm. Ends on 6th by 3:00pm"
      #
      if self.program.residential?
        # DO NOTHING
        # self.teacher.teacher_schedules.where('state IN (?) AND program_id = ?', ::ProgramTeacherSchedule::CONNECTED_STATES, self.program_id).update_all(:timing_str => self.program.timing_str)
      else
        timing_str = self.program.has_intro? ? self.program.timing_str.split(" (Session) ").last : self.program.timing_str
        announced_timings = timing_str.blank? ? [] : timing_str.split(", ")
        teacher_schedules = self.teacher.teacher_schedules.where('state IN (?) AND program_id = ?', ::ProgramTeacherSchedule::CONNECTED_STATES, self.program_id)
        index = 0
        teacher_schedules.each { |ts|
          # fill the announced_timings on first-cum-first-serve basis, blank out the remaining
          ts.timing_str = index < announced_timings.length ? announced_timings[index-1] : ""
          ts.save
          index = index + 1
        }
      end
    end
  end

  def if_program_started!
    self.send(::Program::STARTED) if self.program.in_progress?
  end


  def can_unblock?
    # if minimum number of teachers + 1 - teachers are attached
    if (self.program.minimum_teachers_connected?(1))
      if self.teacher.full_time?
        return true if User.current_user.is? :zao, :center_id => self.program.center_id
      else
        return true if User.current_user.is? :center_scheduler, :center_id => self.program.center_id
      end
    end

    if self.teacher.full_time?
      if (User.current_user.is? :zao, :center_id => self.program.center_id)
        if self.program.venue_approved?
          self.errors[:base] << "Cannot release teacher. Venue linked to the program has already gone for payment request. Please add a teacher and try again."
          return false
        end
        return true
      end
    else
      if User.current_user.is? :sector_coordinator, :center_id => self.program.center_id
        if self.program.venue_approved?
          self.errors[:base] << "Cannot release teacher. Venue linked to the program has already gone for payment request. Please add a teacher and try again."
          return false
        end
        return true
      end

      if User.current_user.is? :center_scheduler, :center_id => self.program.center_id
        if self.program.venue_approval_requested?
          self.errors[:base] << "Cannot release teacher. Venue linked to the program has already gone for payment request. Please add a teacher and try again."
          return false
        end
        return true
      end
    end

    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end


  def can_approve_release?
    if self.teacher.full_time?
      unless self.is_zao?
        self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
        return false
      end
    else
      unless self.is_sector_coordinator?
        self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
        return false
      end
    end

    role   = self.teacher_schedule.role
    # find all the timings for which the specific teacher has active teacher schedule attached to the program
    timing_ids = self.program.teacher_schedules.where("teacher_id = ? AND state IN (?) AND role = ?",self.teacher_id, CONNECTED_STATES, role).pluck(:timing_id)

    timing_ids.each { |timing_id|
      if ((self.program.no_of_teachers_connected(role, timing_id) <= self.program.minimum_no_of_teacher(role)) && self.program.venue_approved?)
        self.errors[:base] << "Cannot remove teacher. Number of #{role} needed for #{Timing(timing_id).pluck(:name)} session will become less than the number needed. Please add another #{role} and try again."
        return false
      end
    }
    return true
  end


  def can_mark_assign_to_unavailable?
    if self.teacher.full_time?
      unless self.is_zao?
        self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
        return false
      end
    else
      unless self.is_sector_coordinator?
        self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
        return false
      end
    end

    role = self.teacher_schedule.role
    # find all the timings for which the specific teacher has active teacher schedule attached to the program
    timing_ids = self.program.teacher_schedules.where("teacher_id = ? AND state IN (?) AND role = ?",self.teacher_id, CONNECTED_STATES, role).pluck(:timing_id)

    timing_ids.each { |timing_id|
      if ((self.program.no_of_teachers_connected(role, timing_id) <= self.program.minimum_no_of_teacher(role)) && self.program.venue_approved?)
        self.errors[:base] << "Cannot remove teacher. Number of #{role} needed for #{Timing(timing_id).pluck(:name)} session will become less than the number needed. Please add another #{role} and try again."
        return false
      end
    }

    return true
  end


  def is_teacher?
    # super_admin can perform actions on behalf of the teacher
    return true if User.current_user.is? :super_admin
    if User.current_user != self.teacher.user
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    end
    return true
  end

  def is_center_scheduler?
    return true if !self.teacher.full_time? && (User.current_user.is? :center_scheduler, :center_id => self.program.center_id)
    # HACK - commenting out for now, because the function is being combined in OR clause
    # where error might be still thrown in un-needed cases
    # self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def is_sector_coordinator?
    return true if !self.teacher.full_time? && (User.current_user.is? :sector_coordinator, :center_id => self.program.center_id)
    # HACK - commenting out for now, because the function is being combined in OR clause
    # where error might be still thrown in un-needed cases
    #self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def is_zao?
    return true if User.current_user.is? :zao, :center_id => self.program.center_id
    # HACK - commenting out for now, because the function is being combined in OR clause
    # where error might be still thrown in un-needed cases
    #self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def initialize(*args)
    super(*args)
  end


  def update_role_and_centers_for_notification!(role, from_state, to_state, on_event, centers, teachers)
    updated_role = role

    # send a block-request notification only to primary zones
    if to_state.include?(STATE_BLOCK_REQUESTED) and
        role.name == ::User::ROLE_ACCESS_HIERARCHY[:center_scheduler][:text]
      # only to zao if full-time teacher
      updated_role = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:zao][:text]) if self.teacher.full_time?
      return updated_role, (self.teacher.primary_zones_centers & self.teacher.centers)
    end

    # send a block-request cancel or reject notification to all zones
    if from_state.include?(STATE_BLOCK_REQUESTED) and to_state.include?(::TeacherSchedule::STATE_AVAILABLE) and
        role.name == ::User::ROLE_ACCESS_HIERARCHY[:center_scheduler][:text]
      # only to zao if full-time teacher
      updated_role = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:zao][:text]) if self.teacher.full_time?
      return updated_role, self.teacher.centers
    end

    # send a block approved notification to zone specified as per program center
    if from_state.include?(STATE_BLOCK_REQUESTED) and to_state.include?(STATE_BLOCKED) and on_event.include?(EVENT_APPROVE) and
        role.name == ::User::ROLE_ACCESS_HIERARCHY[:center_scheduler][:text]
      # only to zao if full-time teacher
      updated_role = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:zao][:text]) if self.teacher.full_time?
      return updated_role, centers
    end

    return updated_role, centers
  end

  def update_users_for_notification!(users, role, from_state, to_state, on_event, centers, teachers)
    updated_users = users

    # if full_time teacher, send release notification *only* to the coordinator who blocked
    if to_state.include?(STATE_RELEASE_REQUESTED) and
        role.name == ::User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text] and
        self.teacher.full_time?
      return [User.find(self.blocked_by_user_id)]
    end

    # if full_time teacher, then don't sent release notification to teacher (from block_requested)
    if from_state.include?(STATE_BLOCK_REQUESTED) and to_state.include?(::TeacherSchedule::STATE_AVAILABLE) and
        role.name == ::User::ROLE_ACCESS_HIERARCHY[:teacher][:text] and self.teacher.full_time?
      return []
    end

    return updated_users
  end

  def blockable_part_time_teachers(role)
    return [] if self.program.nil?
    program = self.program

    # NOTE: For part-time teachers we are checking the center(s) to which they are presently attached,
    # as well as the center for which the schedule is published. This is to avoid cases where they published
    # availability schedule for some center, but were later un-attached from the center. In such cases, we
    # are not modifying their availability schedule, but prevent scheduler from accidently scheduling them
    # for the un-attached center

    # get all part-time teachers for specific program type, for the specified role, attached to the specified center
    program_types_teachers_str = ::Teacher::PROGRAM_TYPES_TABLES[role]
    teacher_ids = Teacher.joins("JOIN #{program_types_teachers_str} ON #{program_types_teachers_str}.teacher_id = teachers.id").
                          joins("JOIN centers_teachers ON centers_teachers.teacher_id = teachers.id").
                          where("#{program_types_teachers_str}.program_type_id = ? AND teachers.full_time = ? AND teachers.state IN (?) AND centers_teachers.center_id = ?",
                          program.program_donation.program_type_id, false, [::Teacher::STATE_ATTACHED], program.center_id).readonly(false).pluck(:id)
    teacher_ids = teacher_ids.uniq

    teacher_schedules = []
    # if teacher is available for *any* of timings (valid for all days) specified in the program for the specified center (as per published schedule)
    timing_ids_valid_all_days = program.has_intro? ? program.intro_timing_ids : program.timing_ids
    teacher_schedules += TeacherSchedule.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").
                                        joins("JOIN teachers ON teachers.id = teacher_schedules.teacher_id").
                                        where(['teacher_schedules.start_date <= ? AND teacher_schedules.end_date >= ? AND teacher_schedules.timing_id IN (?) AND teacher_schedules.state = ? AND centers_teacher_schedules.center_id = ? AND teachers.id IN (?)',
                                        program.start_date.to_date, program.end_date.to_date, timing_ids_valid_all_days,
                                        ::TeacherSchedule::STATE_AVAILABLE, program.center_id , teacher_ids]).readonly(false).all unless timing_ids_valid_all_days.blank?

    # if teacher is available for *any* of other timings specified in the program for the specified center (as per published schedule)
    other_timing_ids = program.has_intro? ? (program.timing_ids - program.intro_timing_ids) : []
    teacher_schedules += TeacherSchedule.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").
                                        joins("JOIN teachers ON teachers.id = teacher_schedules.teacher_id").
                                        where(['teacher_schedules.start_date <= ? AND teacher_schedules.end_date >= ? AND teacher_schedules.timing_id IN (?) AND teacher_schedules.state = ? AND centers_teacher_schedules.center_id = ? AND teachers.id IN (?)',
                                        (program.start_date.to_date + 1.day), program.end_date.to_date, other_timing_ids,
                                        ::TeacherSchedule::STATE_AVAILABLE, program.center_id , teacher_ids]).readonly(false).all unless other_timing_ids.blank?

    blockable = []
      teacher_schedules.each { |teacher_schedule|
      #next unless teacher_ids.include?(teacher_schedule.teacher_id)
      teacher = teacher_schedule.teacher
      b = blockable.find {|e| e[:teacher] == teacher}
      if b.blank?
        b = {:teacher => teacher, :timing_ids => []}
        blockable << b
      end
      b[:timing_ids] << teacher_schedule.timing_id
    }
    blockable

    #
    # NOTE:
    # 1... Right now we are not explicitly handling full_day availability of a part-time teacher
    # for a non-residential program. E.g., if part-time teacher is available for any of the timing(s) of
    # IE 7-Day, we will not explicitly check if teacher is available for all timings on initiation day.
    # We will still allow the teacher to be scheduled for initiation day.
    # 2... But in case the teacher has been blocked for some other program_type on the initiation day
    # then the teacher cannot be blocked. This is handled for all teacher types in blockable_teachers
    #
    #
  end


  def blockable_full_time_teachers(role)
    return [] if self.program.nil?

    program = self.program

    teachers = []
    # get all full time teachers for specific program_type, for the specified role, attached to the specified zone
    program_types_teachers_str = ::Teacher::PROGRAM_TYPES_TABLES[role]
    # primary zones
    teachers += Teacher.joins("JOIN zones_teachers on teachers.id = zones_teachers.teacher_id").
                       joins("JOIN #{program_types_teachers_str} ON #{program_types_teachers_str}.teacher_id = teachers.id").
                       where("#{program_types_teachers_str}.program_type_id = ? AND teachers.full_time = ? AND zones_teachers.zone_id = ? AND teachers.state IN (?)",
                       program.program_donation.program_type_id, true, self.program.center.zone.id, [::Teacher::STATE_ATTACHED]).readonly(false)
    # secondary zones
    teachers += Teacher.joins("JOIN secondary_zones_teachers on teachers.id = secondary_zones_teachers.teacher_id").
                       joins("JOIN #{program_types_teachers_str} ON #{program_types_teachers_str}.teacher_id = teachers.id").
                       where("#{program_types_teachers_str}.program_type_id = ? AND teachers.full_time = ? AND secondary_zones_teachers.zone_id = ? AND teachers.state IN (?)",
                      program.program_donation.program_type_id, true, self.program.center.zone.id, [::Teacher::STATE_ATTACHED]).readonly(false)
    teachers = teachers.uniq
    blockable = []

    ts = TeacherSchedule.new
    ts.program = program
    # For each of timing(s) check if the teacher_schedule overlaps with any existing schedule
    teachers.each {|teacher|
      ts.teacher_id = teacher.id
      program.timing_ids.each { |timing_id|
        ts.timing_id = timing_id
        # if program schedule does not overlap any other schedule for the teacher
        unless ts.schedule_overlaps?
          b = blockable.find {|e| e[:teacher] == teacher}
          if b.blank?
            b = {:teacher => teacher, :timing_ids => []}
            blockable << b
          end
          b[:timing_ids] << timing_id
        end
      }
    }
    blockable
  end

  def blockable_teachers(role)
    trs = []
    trs += self.blockable_part_time_teachers(role) if (User.current_user.is? :center_scheduler, :center_id => self.program.center_id)
    trs +=  self.blockable_full_time_teachers(role) if (User.current_user.is? :zao, :center_id => self.program.center_id)
    # Anyway they are going to be unique, since we splitting into part-time and full-time, still ...
    teachers = trs.uniq

    return teachers if not (self.program.residential? or self.program.has_full_day?)

    blockable = []
    full_day_timing_ids = Timing.pluck(:id)
    full_day_dates = self.program.program_donation.program_type.full_days.map{ |d| program.start_date + (d-1).days}
    if self.program.residential?
      # remove teachers which are not available full-day
      teachers.each{ |t|
        next if full_day_timing_ids.sort != t[:timing_ids].sort
        blockable << t
      }
    else
      # remove teachers which are blocked for any portion of the full-days for the program
      ts = TeacherSchedule.new
      ts.program = self.program
      teachers.each {|tr|
        overlaps = false
        ts.teacher_id = tr[:teacher].id
        if full_day_timing_ids != tr[:timing_ids].sort
          full_day_dates.each { |full_day_date|
            break if overlaps
            overlaps = true if TeacherSchedule.overlapping_full_day_blocks(ts, full_day_date).count() > 0
          }
        end
        blockable << tr unless overlaps
      }
    end
    blockable
  end


  def blockable_programs_for_part_time_teachers(role)
    return [] if self.teacher.nil? or self.teacher.full_time?

    # teacher can be scheduled for multiple centers, but the blockable programs
    # should only come from the centers that I am enabled to schedule
    teacher = self.teacher
    center_ids = []
    center_ids += current_user.accessible_center_ids(:center_scheduler) if User.current_user.is? :center_scheduler, :for => :any, :center_id => teacher.center_ids
    center_ids &= teacher.center_ids

    # NOTE: We cannot add a teacher once the program has started
    programs = Program.where('center_id IN (?) AND start_date > ? AND state NOT IN (?)', center_ids, Time.zone.now, ::Program::CLOSED_STATES).order('start_date ASC').all
    blockable_programs = []
    programs.each {|program|
      timing_ids = teacher.can_be_blocked_by?(program, role)
      blockable_programs << {:program => program, :timing_ids => timing_ids} unless timing_ids.blank?
    }
    blockable_programs
  end

  def blockable_programs_for_full_time_teachers(role)
    return [] if self.teacher.nil? or !self.teacher.full_time?

    # teacher can be scheduled for multiple centers, but the blockable programs
    # should only come from the centers that I am enabled to schedule
    teacher = self.teacher
    center_ids = []
    center_ids += current_user.accessible_center_ids(:zao) if User.current_user.is? :zao, :for => :any, :center_id => teacher.center_ids
    # Ideally this condition is not needed for full-time, since we mark them for zones, and not centers
    center_ids &= teacher.center_ids

    # NOTE: We cannot add a teacher once the program has started
    # All programs in all centers where the current user can schedule teachers
    programs = Program.where('center_id IN (?) AND start_date > ? AND state NOT IN (?)', center_ids, Time.zone.now, ::Program::CLOSED_STATES).order('start_date ASC').all
    blockable_programs = []
    programs.each {|program|
      timing_ids = teacher.can_be_blocked_by?(program, role)
      blockable_programs << {:program => program, :timing_ids => timing_ids} unless timing_ids.blank?
    }
    blockable_programs
  end

  def blockable_programs(role)
    # NOTE: blockable_programs_for_full_time_teachers and blockable_programs_for_part_time_teachers
    # can be merged, but not merging, in case there is any change in scheduling later for part-time
    # and full-time later
    if self.teacher.full_time?
      programs = self.blockable_programs_for_full_time_teachers(role)
    else
      programs = self.blockable_programs_for_part_time_teachers(role)
    end

    # check if residential programs or program with full_days meet all conditions
    blockable = []
    full_day_timing_ids = Timing.pluck(:id)
    ts = TeacherSchedule.new
    ts.teacher_id = self.teacher.id

    programs.each{ |p|
      # remove residential programs where teacher is not available full-day
      if p[:program].residential?
        next if full_day_timing_ids.sort != p[:timing_ids].sort
      elsif  p[:program].has_full_day?
        # remove programs where teacher is blocked for any portion of the full-days for the program
        ts.program = p[:program]
        full_day_dates = ts.program.program_donation.program_type.full_days.map{ |d| ts.program.start_date + (d-1).days}
        overlaps = false
        full_day_dates.each { |full_day_date|
          break if overlaps
          overlaps = true if TeacherSchedule.overlapping_full_day_blocks(ts, full_day_date).count() > 0
        }
        next if overlaps
      end
      blockable << p
    }
    blockable
  end

  def block_part_time_teacher_schedule!(program, teacher, timing_ids, event)
    timing_ids.each {|timing_id|
#      ts = teacher.teacher_schedules.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").where('teacher_schedules.start_date <= ? AND teacher_schedules.end_date >= ? AND teacher_schedules.timing_id = ? AND teacher_schedules.state = ? AND (centers_teacher_schedules.center_id = ? OR centers_teacher_schedules.center_id IS NULL) AND (teacher_schedules.program_type_id = ? OR teacher_schedules.program_type_id IS NULL) ',
#                                                                                                                                                           program.start_date.to_date, program.end_date.to_date, t.id,
#                                                                                                                                                           ::TeacherSchedule::STATE_AVAILABLE, program.center_id, program.program_donation.program_type_id).readonly(false).first
      start_date = program.start_date
      start_date = start_date + 1.day if (program.has_intro? and not program.intro_timing_ids.include?(timing_id))

      ts = teacher.teacher_schedules.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").
                                      where('teacher_schedules.start_date <= ? AND teacher_schedules.end_date >= ? AND teacher_schedules.timing_id = ? AND teacher_schedules.state = ? AND centers_teacher_schedules.center_id = ? ',
                                      start_date.to_date, program.end_date.to_date, timing_id,
                                      ::TeacherSchedule::STATE_AVAILABLE, program.center_id).readonly(false).first
      # split this schedule as per program dates
      ts.split_schedule!(start_date.to_date, program.end_date.to_date)
      # TODO - check if break if correct idea, we should rollback previous change(s) in this loop
      if !ts.errors.empty?
        self.errors[:base] << ts.errors.full_messages
        break
      end
      ts.program_id = program.id
      ts.timing_str = Timing.find(timing_id).name
      ts.blocked_by_user_id = current_user.id
      ts.role = teacher_role
      ts.current_user = current_user
      ts.state = (event == EVENT_BLOCK) ? STATE_BLOCKED : STATE_BLOCK_REQUESTED
      ts.clear_comments!
      # This is a hack to store the last update
      ts.store_last_update!(current_user, ::TeacherSchedule::STATE_AVAILABLE, ts.state, event)
      #ts.save(:validate => false)
      ts.save
      # TODO - check if break if correct idea, we should rollback previous change(s) in this loop
      if !ts.errors.empty?
        self.errors[:base] << ts.errors.full_messages
        break
      end
      self.teacher_schedule_id = ts.id
      # HACK - to ensure proper logging
      self.id = ts.id
    }
  end

  def block_full_time_teacher_schedule!(program, teacher, timing_ids, event)
    timing_ids.each {|timing_id|
      start_date = program.start_date
      start_date = start_date + 1.day if (program.has_intro? and not program.intro_timing_ids.include?(timing_id))

      # create a new schedule of the same duration as the program, and mark it as available
      ts = TeacherSchedule.new
      ts.teacher_id = teacher.id
      ts.start_date = start_date
      ts.end_date = program.end_date
      ts.centers = [program.center]
      ts.program_id = program.id
      ts.timing_id = timing_id
      ts.timing_str = Timing.find(timing_id).name
      ts.blocked_by_user_id = current_user.id
      ts.role = teacher_role
      ts.current_user = current_user
      ts.state = (event == EVENT_BLOCK) ? STATE_BLOCKED : STATE_BLOCK_REQUESTED
      ts.clear_comments!
      # This is a hack to store the last update
      ts.store_last_update!(current_user, ::TeacherSchedule::STATE_AVAILABLE, ts.state, event)
      #ts.save(:validate => false)
      ts.save
      # TODO - check if break if correct idea, we should rollback previous change(s) in this loop
      if !ts.errors.empty?
        self.errors[:base] << ts.errors.full_messages
        break
      end
      self.teacher_schedule_id = ts.id
      # HACK - to ensure proper logging
      self.id = ts.id
    }
  end


  # Incoming params - params => {"program_id"=>"3", "teacher_id"=>"1"}
  # 1. given the teacher_id, find the schedules relevant for the program_id
  # 2. split the schedule, marking the one against program - with program_id and state
  def block_teacher_schedule!(params)
    timing_ids = ([params[:timing_ids]].flatten).reject(&:blank?).map{|x| x.to_i}
    if timing_ids.blank?
      self.errors[:timings] << " cannot be blank."
      return
    end
    program = Program.find(params[:program_id])
    teacher = Teacher.find(params[:teacher_id])
    event = self.can_create? ? EVENT_BLOCK : EVENT_REQUEST_BLOCK
    if teacher.full_time?
      self.block_full_time_teacher_schedule!(program, teacher, timing_ids, event)
    else
      self.block_part_time_teacher_schedule!(program, teacher, timing_ids, event)
    end

    # Not storing to activity_log here, since already stored in underlying teacher_schedules
    # self.log_last_activity(current_user, ::TeacherSchedule::STATE_AVAILABLE, ::ProgramTeacherSchedule::STATE_BLOCKED, ::ProgramTeacherSchedule::EVENT_BLOCK)
    # This is a hack, just to make sure the relevant notifications are sent out
    self.state = ::TeacherSchedule::STATE_AVAILABLE
    # TODO - check whether errors need to be checked here
    self.send(event) if self.errors.empty?
  end


  # NOTE: ProgramTeacherSchedule is **NOT** using ActiveRecord class functions like save
  def update(role=nil, trigger=EVENT_UNKNOWN)

    # if the state was updated to ::TeacherSchedule::STATE_AVAILABLE or ::TeacherSchedule::STATE_UNAVAILABLE
    if (::TeacherSchedule::STATE_PUBLISHED + [::TeacherSchedule::STATE_AVAILABLE_EXPIRED]).include?(self.state)
      program_id = nil
      blocked_by_user_id = nil
      updated_role = ""
    else
      program_id = self.program_id
      blocked_by_user_id = self.blocked_by_user_id
      updated_role = self.teacher_role
    end
    # Cannot update using sql because we need to combine the slots also
    # TeacherSchedule.where('program_id = ? AND teacher_id = ?', self.program.id, self.teacher_id).update_all(
    #     {:state => self.state, :program_id => program_id, :blocked_by_user_id => self.blocked_by_user_id})

    #old_state = ::TeacherSchedule::STATE_UNKNOWN
    role = self.teacher_role if role.blank?
    teacher_schedules = TeacherSchedule.where('program_id = ? AND teacher_id = ? AND role = ?', self.program_id, self.teacher_id, role)
    teacher_schedules.each {|ts|
      # 1. update the state of all teacher_schedule(s) for a teacher, and program
      #old_state = ts.state
      ts.store_last_update!(User.current_user, ts.state, self.state, trigger)
      ts.state = self.state
      ts.program_id = program_id
      ts.blocked_by_user_id = blocked_by_user_id
      ts.timing_str = ts.timing.name if program_id.nil?
      ts.role = updated_role
      ts.comments = self.comments.nil? ? "" : self.comments
      ts.feedback = self.feedback unless self.feedback.nil?
      ts.save
      ## TODO - check if break if correct idea, we should rollback previous change(s) in this loop
      if !ts.errors.empty?
        self.errors[:base] << ts.errors.full_messages
        break
      end

      # if they have been marked Available or unavailable,
      if (::TeacherSchedule::STATE_PUBLISHED + [::TeacherSchedule::STATE_AVAILABLE_EXPIRED]).include?(ts.state)
        # if full_time teacher then delete the schedule
        # else check if combine_consecutive_slots for part_time
        if self.teacher.full_time?
            ts.destroy
        elsif ts.can_combine_consecutive_schedules?
          ts.clear_comments!
          ts.clear_last_update!
          ts.combine_consecutive_schedules!
          # TODO - check if break if correct idea, we should rollback previous change(s) in this loop
          if !ts.save
            self.errors[:base] << ts.errors.full_messages
            break
          end
        end
      end
      # This is a HACK to store to activity log - NOT needed, since activity is logged in underlying teacher_schedules
      # self.log_last_activity(User.current_user, old_state, self.state, trigger)
      self.deleted_program_id = self.program_id if program_id.nil?
      self.program_id = program_id
    }
  end

  def can_create?(center_ids = [self.program.center_id.to_i])
    unless self.teacher.nil?
      center_ids_in_primary_zone = self.teacher.primary_zones_center_ids & center_ids
      return false if center_ids_in_primary_zone.blank?
      if self.teacher.full_time?
        # adding :any condition, in case teacher shared across zones
        return true if User.current_user.is? :zao, :for => :any, :center_id => center_ids_in_primary_zone
      else
        return true if User.current_user.is? :center_scheduler, :for => :any, :center_id => center_ids_in_primary_zone
      end
    else
      # This case happens when getting called from program_teacher_schedules_controller on new request -->
      # :for => :any does not make sense here, since, the only case we do not have the teacher is when
      # we have a program to start with, and we are trying to associate a teacher to it. In that case
      # the center_ids is the center to which the program is attached. For now letting it be :any
      return true if User.current_user.is? :center_scheduler, :for => :any, :center_id => center_ids
    end
    return false
  end

  def can_create_block_request?(center_ids = [self.program.center_id.to_i])
    return false if self.can_create?(center_ids)
    unless self.teacher.nil?
      center_ids_in_secondary_zone = self.teacher.secondary_zones_center_ids & center_ids
      return false if center_ids_in_secondary_zone.blank?
      if self.teacher.full_time?
        # adding :any condition, in case teacher shared across zones
        return true if User.current_user.is? :zao, :for => :any, :center_id => center_ids_in_secondary_zone
      else
        return true if User.current_user.is? :center_scheduler, :for => :any, :center_id => center_ids_in_secondary_zone
      end
    else
      # This case happens when getting called from program_teacher_schedules_controller on new request -->
      # :for => :any does not make sense here, since, the only case we do not have the teacher is when
      # we have a program to start with, and we are trying to associate a teacher to it. In that case
      # the center_ids is the center to which the program is attached. For now letting it be :any
      return true if User.current_user.is? :center_scheduler, :for => :any, :center_id => center_ids
    end
    return false
  end


  def can_approve_block?
    if self.teacher.full_time?
      return true if User.current_user.is? :zao, :for => :any, :center_id => self.teacher.primary_zones_center_ids
    else
      return true if User.current_user.is? :center_scheduler, :for => :any, :center_id => self.teacher.primary_zones_center_ids
    end
    return false
  end

  def can_update?
    center_ids = [self.program.center_id.to_i]
    center_ids += self.teacher.primary_zones_center_ids if self.state == ::ProgramTeacherSchedule::STATE_BLOCK_REQUESTED
    if self.teacher.full_time?
      return true if User.current_user.is? :zao, :for => :any, :center_id => center_ids
    else
      return true if User.current_user.is? :center_scheduler, :for => :any, :center_id => center_ids
    end
    return true if User.current_user == self.teacher.user
    return false
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
    self.program.nil? ? " for #{self.teacher.user.fullname}, #{self.timing.name}(#{self.start_date.strftime('%d %B')}-#{self.end_date.strftime('%d %B %Y')}) "
    : " for Program ##{self.program.id} #{self.program.name} and Teacher ##{self.teacher.id} #{self.teacher.user.fullname}"
  end

  def friendly_name_for_sms
    self.program.nil? ? "Teacher Schedule ##{self.id} for #{self.teacher.user.firstname}"
    : "Program-Teacher Schedule ##{self.id} for #{self.teacher.user.firstname}"
  end


end
