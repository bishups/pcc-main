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

  attr_accessor :teacher_id, :teacher, :blocked_by_user_id, :program, :program_id, :deleted_program, :deleted_program_id, :teacher_schedule, :teacher_schedule_id, :comments, :feedback, :comment_category
  attr_accessor :current_user, :state, :teacher_role

  # HACK - for logging
  attr_accessor :id
  # attr_accessible :program, :teacher_id, :reserving_user_id
  # validates :program_id, :teacher_id, :reserving_user_id, :presence => true

  belongs_to :program
  #STATE_UNKNOWN  = :unknown
  #STATE_UNKNOWN             = 'Unknown'
  STATE_BLOCKED             = 'Blocked'
  STATE_ASSIGNED            = 'Assigned'
  STATE_RELEASE_REQUESTED   = 'Release Requested'
  STATE_IN_CLASS            = 'In Class'
  STATE_COMPLETED_CLASS     = 'Completed Class'

  CONNECTED_STATES = [STATE_BLOCKED, STATE_RELEASE_REQUESTED, STATE_ASSIGNED, STATE_IN_CLASS]
  FINAL_STATES = [STATE_COMPLETED_CLASS]


  # Events
  EVENT_BLOCK              = 'Block'
  EVENT_REQUEST_RELEASE    = 'Request Release'
  EVENT_RELEASE            = 'Release'
  # Unknown Event, used only for logging
  EVENT_UNKNOWN = 'Unknown'

  PROCESSABLE_EVENTS = [
      EVENT_REQUEST_RELEASE, EVENT_RELEASE
  ]

  EVENTS_WITH_COMMENTS = [EVENT_RELEASE, EVENT_REQUEST_RELEASE]
  EVENTS_WITH_FEEDBACK = []


  state_machine :state, :initial => ::TeacherSchedule::STATE_AVAILABLE do

    event EVENT_BLOCK do
      transition ::TeacherSchedule::STATE_AVAILABLE => STATE_BLOCKED, :if => lambda {|t| t.can_create?}
    end
    before_transition ::TeacherSchedule::STATE_AVAILABLE => STATE_BLOCKED, :do => :can_block?
    after_transition any => STATE_BLOCKED, :do => :on_block

    event ::Program::DROPPED do
      transition STATE_BLOCKED => ::TeacherSchedule::STATE_AVAILABLE
    end

    event EVENT_RELEASE do
      transition STATE_BLOCKED => ::TeacherSchedule::STATE_AVAILABLE, :if => lambda {|pts| pts.is_center_scheduler? || pts.is_full_time_teacher_scheduler? || pts.is_zao? }
      transition STATE_ASSIGNED => ::TeacherSchedule::STATE_UNAVAILABLE, :if => lambda {|pts| pts.is_sector_coordinator? || pts.is_full_time_teacher_scheduler? || pts.is_zao?}
      transition STATE_RELEASE_REQUESTED => ::TeacherSchedule::STATE_UNAVAILABLE, :if => lambda {|pts| pts.is_sector_coordinator? || pts.is_full_time_teacher_scheduler? || pts.is_zao? }
    end
    # move the before transition, privilege part of the check to :if condition of the transition
    before_transition STATE_BLOCKED => ::TeacherSchedule::STATE_AVAILABLE do |pts, transition|
        pts.can_unblock? unless transition.event == ::Program::DROPPED
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
      transition [STATE_BLOCKED, STATE_RELEASE_REQUESTED] => ::TeacherSchedule::STATE_AVAILABLE_EXPIRED
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


  def on_block
    self.if_program_announced!
  end

  def if_program_announced!
    self.send(::Program::ANNOUNCED) if self.program.is_announced? && self.program.is_active?
  end

  def if_program_started!
    self.send(::Program::STARTED) if self.program.in_progress?
  end


  def can_unblock?
    if (self.program.no_of_main_teachers_connected > self.program.minimum_no_of_main_teacher) && (self.program.no_of_co_teachers_connected > self.program.minimum_no_of_co_teacher)
      if self.teacher.full_time?
        return true if User.current_user.is? :full_time_teacher_scheduler, :center_id => self.program.center_id
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

      if (User.current_user.is? :full_time_teacher_scheduler, :center_id => self.program.center_id) || (User.current_user.is? :full_time_teacher_scheduler, :center_id => self.program.center_id && self.teacher.full_time? )
        if self.program.venue_approval_requested?
          self.errors[:base] << "Cannot release teacher. Venue linked to the program has already gone for payment request. Please add a teacher and try again."
          return false
        end
        return true
      end
    else
      if (User.current_user.is? :sector_coordinator, :center_id => self.program.center_id)
        if self.program.venue_approved?
          self.errors[:base] << "Cannot release teacher. Venue linked to the program has already gone for payment request. Please add a teacher and try again."
          return false
        end
        return true
      end

      if (User.current_user.is? :center_scheduler, :center_id => self.program.center_id) || (User.current_user.is? :full_time_teacher_scheduler, :center_id => self.program.center_id && self.teacher.full_time? )
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
      unless self.is_full_time_teacher_scheduler? || self.is_zao?
        self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
        return false
      end
    else
      unless self.is_sector_coordinator?
        self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
        return false
      end
    end

    if ((self.program.no_of_main_teachers_connected <= self.program.minimum_no_of_main_teacher) && self.program.venue_approved?)
      self.errors[:base] << "Cannot remove teacher. Number of teachers needed will become less than the number needed. Please add another teacher and try again."
      return false
    end

    if ((self.program.no_of_co_teachers_connected <= self.program.minimum_no_of_co_teacher) && self.program.venue_approved?)
      self.errors[:base] << "Cannot remove co-teacher. Number of co-teachers needed will become less than the number needed. Please add another co-teacher and try again."
      return false
    end

    return true
  end


  def can_mark_assign_to_unavailable?
    if self.teacher.full_time?
      unless self.is_full_time_teacher_scheduler? || self.is_zao?
        self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
        return false
      end
    else
      unless self.is_sector_coordinator?
        self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
        return false
      end
    end

    if self.program.no_of_main_teachers_connected <= self.program.minimum_no_of_main_teacher
      self.errors[:base] << "Cannot remove teacher. Number of teachers needed will become less than the number needed. Please add another teacher and try again."
      return false
    end

    if self.program.no_of_co_teachers_connected <= self.program.minimum_no_of_co_teacher
      self.errors[:base] << "Cannot remove co-teacher. Number of co-teachers needed will become less than the number needed. Please add another co-teacher and try again."
      return false
    end

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

  def is_full_time_teacher_scheduler?
    return true if (self.teacher.full_time?) && (User.current_user.is? :full_time_teacher_scheduler, :center_id => self.program.center_id)
    # HACK - commenting out for now, because the function is being combined in OR clause
    # where error might be still thrown in un-needed cases
    #self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
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

  def update_users_for_notification!(users, role, from_state, to_state, on_event, centers, teachers)
    updated_users = users
    if to_state.include?(STATE_RELEASE_REQUESTED) and role.name == ::User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]
      # if full_time teacher, send release notification only to the coordinator who blocked
      updated_users = [User.find(self.blocked_by_user_id)] if self.teacher.full_time?
    end
    updated_users
  end

  def blockable_part_time_teachers(co_teacher)
    return [] if self.program.nil?
    program = self.program

    # NOTE: For now ignoring the co_teacher flag for part-time teachers
    return [] if co_teacher
    # This is because --
    # 1. In case of part-time teachers, they are publishing their schedule based on timings of a specific program-type
    # 2. Even they publish the availability timings of program_type A, we can still book them for program_type B
    #    provided the two timings match exactly, and that they are training for both A and B.
    # 3. TODO - the thing that needs to be done --
    #   3.1 We do not have separate program_type for Organizing, so that they can publish schedule for that
    #   3.2 We do split one time slot. E.g, if they give full-day availability, are we need only morning slot
    #       we will not split full-day slot. And more-ever the availability check will fail because it is not
    #       exactly matching, even though the person is available.
    # 4. Because of point 3., even though we can handle point 2., as of now we are not handling it

    # get all part-time teachers for specific program type
    #teacher_ids = ProgramTypesTeachers.find_all_by_program_type_id(program.program_donation.program_type_id).map { |pts| pts[:teacher_id] }
    teacher_ids = Teacher.joins("JOIN program_types_teachers ON program_types_teachers.teacher_id = teachers.id").where('program_types_teachers.program_type_id = ? AND teachers.full_time = ? AND teachers.state IN (?)',
                                                                                                                        program.program_donation.program_type_id, false, [::Teacher::STATE_ATTACHED]).readonly(false).pluck(:id)

    program.timings.each {|t|
      # if teacher is available for each of timing specified in the program for the specified center
      teacher_ids &= TeacherSchedule.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").where(['teacher_schedules.start_date <= ? AND teacher_schedules.end_date >= ? AND teacher_schedules.timing_id = ? AND teacher_schedules.state = ? AND (centers_teacher_schedules.center_id = ? OR centers_teacher_schedules.center_id IS NULL)',
                                            program.start_date.to_date, program.end_date.to_date, t.id,
                                            ::TeacherSchedule::STATE_AVAILABLE, program.center_id, ]).pluck(:teacher_id)
    }
    teachers = Teacher.find(teacher_ids)
  end

  def blockable_full_time_teachers(co_teacher)
    return [] if self.program.nil?

    program = self.program

    # don't check specific program type if teacher is marked as co-teacher
    if co_teacher
      teacher_ids = Teacher.where("teachers.full_time = ? AND teachers.zone_id = ? AND teachers.state IN (?)",
                                    true, self.program.center.zone.id, [::Teacher::STATE_ATTACHED]).pluck(:id)
    else
      # retrieve full time teachers for specific program_type that can be blocked, and can be scheduled by current_user
      teacher_ids = Teacher.joins("JOIN program_types_teachers ON program_types_teachers.teacher_id = teachers.id").where('program_types_teachers.program_type_id = ? AND teachers.full_time = ? AND teachers.zone_id = ? AND teachers.state IN (?)',
                                                                                                                          program.program_donation.program_type_id, true, self.program.center.zone.id, [::Teacher::STATE_ATTACHED]).readonly(false).pluck(:id)
    end

    teacher_ids = teacher_ids.uniq
    blockable_teacher_ids = []

    ts = TeacherSchedule.new
    ts.program = program
    # For each of timing(s) check if the teacher_schedule overlaps with any existing schedule
    teacher_ids.each {|teacher_id|
      overlaps = false
      program.timing_ids.each { |timing_id|
        ts.timing_id = timing_id
        ts.teacher_id = teacher_id
        # if program schedule does not overlap any other schedule for the teacher
        if ts.schedule_overlaps?
          overlaps = true
          break
        end
      }
      blockable_teacher_ids << teacher_id unless overlaps
    }
    Teacher.find(blockable_teacher_ids)
  end

  def blockable_teachers(co_teacher = false)
    teachers = []
    teachers += self.blockable_part_time_teachers(co_teacher) if (User.current_user.is? :center_scheduler, :center_id => self.program.center_id)
    teachers += self.blockable_full_time_teachers(co_teacher) if (User.current_user.is? :full_time_teacher_scheduler, :center_id => self.program.center_id) or (User.current_user.is? :zao, :center_id => self.program.center_id)
    teachers
  end


  def blockable_programs_for_part_time_teachers(co_teacher)
    return [] if self.teacher.nil?
    # NOTE: For now ignoring the co_teacher flag for part-time teachers
    # see note in blockable_part_time_teachers function
    return [] if co_teacher

    teacher = self.teacher
    # the list returned here is not a confirmed list, it is a tentative list which might fail validations later
    # TODO - writing the query for confirmed list is too db intensive for now, so skipping it
    # NOTE: We cannot add a teacher once the program has started
    programs = Program.where('center_id IN (?) AND start_date > ? AND state NOT IN (?)', teacher.center_ids, Time.zone.now, ::Program::CLOSED_STATES).order('start_date ASC').all
    blockable_programs = []
    programs.each {|program|
      blockable_programs << program if teacher.can_be_blocked_by?(program, co_teacher)
    }
    blockable_programs
  end

  def blockable_programs_for_full_time_teachers(co_teacher)
    return [] if self.teacher.nil?
    return [] if !self.teacher.full_time?

    teacher = self.teacher
    center_ids = []
    center_ids += current_user.accessible_center_ids(:zao) if User.current_user.is? :full_time_teacher_scheduler, :center_id => teacher.center_ids
    center_ids += current_user.accessible_center_ids(:full_time_teacher_scheduler) if User.current_user.is? :full_time_teacher_scheduler, :center_id => teacher.center_ids

    # NOTE: We cannot add a teacher once the program has started
    # All programs in all centers where the current user can schedule teachers
    programs = Program.where('center_id IN (?) AND start_date > ? AND state NOT IN (?)', center_ids, Time.zone.now, ::Program::CLOSED_STATES).order('start_date ASC').all
    blockable_programs = []
    programs.each {|program|
      blockable_programs << program if teacher.can_be_blocked_by?(program, co_teacher)
    }
    blockable_programs
  end

  def blockable_programs(co_teacher = false)
    if self.teacher.full_time?
      self.blockable_programs_for_full_time_teachers(co_teacher)
    else
      self.blockable_programs_for_part_time_teachers(co_teacher)
    end
  end

  def block_part_time_teacher_schedule!(program, teacher)
    program.timings.each {|t|
#      ts = teacher.teacher_schedules.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").where('teacher_schedules.start_date <= ? AND teacher_schedules.end_date >= ? AND teacher_schedules.timing_id = ? AND teacher_schedules.state = ? AND (centers_teacher_schedules.center_id = ? OR centers_teacher_schedules.center_id IS NULL) AND (teacher_schedules.program_type_id = ? OR teacher_schedules.program_type_id IS NULL) ',
#                                                                                                                                                           program.start_date.to_date, program.end_date.to_date, t.id,
#                                                                                                                                                           ::TeacherSchedule::STATE_AVAILABLE, program.center_id, program.program_donation.program_type_id).readonly(false).first
      ts = teacher.teacher_schedules.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").where('teacher_schedules.start_date <= ? AND teacher_schedules.end_date >= ? AND teacher_schedules.timing_id = ? AND teacher_schedules.state = ? AND (centers_teacher_schedules.center_id = ? OR centers_teacher_schedules.center_id IS NULL) ',
                                                                                                                                                           program.start_date.to_date, program.end_date.to_date, t.id,
                                                                                                                                                           ::TeacherSchedule::STATE_AVAILABLE, program.center_id).readonly(false).first
      # split this schedule as per program dates
      ts.split_schedule!(program.start_date.to_date, program.end_date.to_date)
      # TODO - check if break if correct idea, we should rollback previous change(s) in this loop
      if !ts.errors.empty?
        self.errors[:base] << ts.errors.full_messages
        break
      end
      ts.program_id = program.id
      ts.blocked_by_user_id = current_user.id
      ts.current_user = current_user
      ts.state = ::ProgramTeacherSchedule::STATE_BLOCKED
      ts.clear_comments!
      # This is a hack to store the last update
      ts.store_last_update!(current_user, ::TeacherSchedule::STATE_AVAILABLE, ::ProgramTeacherSchedule::STATE_BLOCKED, ::ProgramTeacherSchedule::EVENT_BLOCK)
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

  def block_full_time_teacher_schedule!(program, teacher)
    program.timings.each {|timing|
      # create a new schedule of the same duration as the program, and mark it as available
      ts = TeacherSchedule.new
      ts.teacher_id = teacher.id
      ts.start_date = program.start_date
      ts.end_date = program.end_date
      ts.centers = [program.center]
      ts.program_id = program.id
      ts.timing_id = timing.id
      ts.blocked_by_user_id = current_user.id
      ts.co_teacher = (teacher_role == ::TeacherSchedule::ROLE_CO_TEACHER)
      ts.current_user = current_user
      ts.state = ::ProgramTeacherSchedule::STATE_BLOCKED
      ts.clear_comments!
      # This is a hack to store the last update
      ts.store_last_update!(current_user, ::TeacherSchedule::STATE_AVAILABLE, ::ProgramTeacherSchedule::STATE_BLOCKED, ::ProgramTeacherSchedule::EVENT_BLOCK)
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
    program = Program.find(params[:program_id])
    teacher = Teacher.find(params[:teacher_id])
    if teacher.full_time?
      self.block_full_time_teacher_schedule!(program, teacher)
    else
      self.block_part_time_teacher_schedule!(program, teacher)
    end

    # Not storing to activity_log here, since already stored in underlying teacher_schedules
    # self.log_last_activity(current_user, ::TeacherSchedule::STATE_AVAILABLE, ::ProgramTeacherSchedule::STATE_BLOCKED, ::ProgramTeacherSchedule::EVENT_BLOCK)
    # This is a hack, just to make sure the relevant notifications are sent out
    self.state = ::TeacherSchedule::STATE_AVAILABLE
    # TODO - check whether errors need to be checked here
    self.send(::ProgramTeacherSchedule::EVENT_BLOCK) if self.errors.empty?
  end


  # NOTE: ProgramTeacherSchedule is **NOT** using ActiveRecord class functions like save
  def update(trigger=EVENT_UNKNOWN)

    # if the state was updated to ::TeacherSchedule::STATE_AVAILABLE or ::TeacherSchedule::STATE_UNAVAILABLE
    if (::TeacherSchedule::STATE_PUBLISHED + [::TeacherSchedule::STATE_AVAILABLE_EXPIRED]).include?(self.state)
      program_id = nil
      blocked_by_user_id = nil
    else
      program_id = self.program_id
      blocked_by_user_id = self.blocked_by_user_id
    end
    # Cannot update using sql because we need to combine the slots also
    # TeacherSchedule.where('program_id = ? AND teacher_id = ?', self.program.id, self.teacher_id).update_all(
    #     {:state => self.state, :program_id => program_id, :blocked_by_user_id => self.blocked_by_user_id})

    #old_state = ::TeacherSchedule::STATE_UNKNOWN
    teacher_schedules = TeacherSchedule.where('program_id = ? AND teacher_id = ?', self.program_id, self.teacher_id)
    teacher_schedules.each {|ts|
      # 1. update the state of all teacher_schedule(s) for a teacher, and program
      #old_state = ts.state
      ts.store_last_update!(User.current_user, ts.state, self.state, trigger)
      ts.state = self.state
      ts.program_id = program_id
      ts.blocked_by_user_id = blocked_by_user_id
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

  def can_create?(center_ids = self.program.center_id)
    if !self.teacher.nil?
      if self.teacher.full_time?
        return true if User.current_user.is? :zao, :center_id => center_ids
        return true if User.current_user.is? :full_time_teacher_scheduler, :center_id => center_ids
      else
        return true if User.current_user.is? :center_scheduler, :for => :any, :center_id => center_ids
      end
    else
      return true if User.current_user.is? :full_time_teacher_scheduler, :center_id => center_ids
      return true if User.current_user.is? :center_scheduler, :for => :any, :center_id => center_ids
    end
    return false
  end

  def can_update?
    if self.teacher.full_time?
      return true if User.current_user.is? :full_time_teacher_scheduler, :center_id => self.program.center_id
      return true if User.current_user.is? :zao, :center_id => self.program.center_id
    else
      return true if User.current_user.is? :center_scheduler, :center_id => self.program.center_id
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
