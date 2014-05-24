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

  attr_accessor :current_user, :state

  # attr_accessible :program, :teacher_id, :reserving_user_id
  # validates :program_id, :teacher_id, :reserving_user_id, :presence => true


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
    after_transition any => STATE_BLOCKED, :do => :if_program_announced!

    event ::Program::DROPPED do
      transition STATE_BLOCKED => ::TeacherSchedule::STATE_AVAILABLE
    end

    event EVENT_RELEASE do
      transition STATE_BLOCKED => ::TeacherSchedule::STATE_AVAILABLE, :if => lambda {|pts| pts.is_center_scheduler? }
      transition STATE_ASSIGNED => ::TeacherSchedule::STATE_UNAVAILABLE, :if => lambda {|pts| pts.is_sector_coordinator? }
      transition STATE_RELEASE_REQUESTED => ::TeacherSchedule::STATE_UNAVAILABLE, :if => lambda {|pts| pts.is_sector_coordinator? }
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
      object.notify(transition.from, transition.to, transition.event, center)
    end

  end


  def can_block?
    return true if self.can_create?
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end


  def if_program_announced!
    self.send(::Program::ANNOUNCED) if self.program.is_announced? && self.program.is_active?
  end

  def if_program_started!
    self.send(::Program::STARTED) if self.program.in_progress?
  end


  def can_unblock?
    if (self.current_user.is? :center_scheduler, :center_id => self.program.center_id) && (self.program.no_of_teachers_connected > self.program.minimum_no_of_teacher)
      return true
    end

    if (self.current_user.is? :sector_coordinator, :center_id => self.program.center_id)
      if self.program.venue_approved?
        self.errors[:base] << "Cannot release teacher. Venue linked to the program has already gone for payment request. Please add a teacher and try again."
        return false
      end
      return true
    end

    if (self.current_user.is? :center_scheduler, :center_id => self.program.center_id)
      if self.program.venue_approval_requested?
        self.errors[:base] << "Cannot release teacher. Venue linked to the program has already gone for payment request. Please add a teacher and try again."
        return false
      end
      return true
    end

    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end


  def can_approve_release?
    return false unless self.is_sector_coordinator?

    if ((self.program.no_of_teachers_connected <= self.program.minimum_no_of_teacher) && self.program.venue_approved?)
      self.errors[:base] << "Cannot remove teacher. Number of teachers needed will become less than the number needed. Please add another teacher and try again."
      return false
    end

    return true
  end


  def can_mark_assign_to_unavailable?
    return false unless self.is_sector_coordinator?

    if self.program.no_of_teachers_connected <= self.program.minimum_no_of_teacher
      self.errors[:base] << "Cannot remove teacher. Number of teachers needed will become less than the number needed. Please add another teacher and try again."
      return false
    end
    return true
  end


  def is_teacher?
    # super_admin can perform actions on behalf of the teacher
    return true if self.current_user.is? :super_admin
    if self.current_user != self.teacher.user
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    end
    return true
  end

  def is_center_scheduler?
    return true if self.current_user.is? :center_scheduler, :center_id => self.program.center_id
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def is_sector_coordinator?
    return true if  self.current_user.is? :sector_coordinator, :center_id => self.program.center_id
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def is_zao?
    return true if self.current_user.is? :zao, :center_id => self.program.center_id
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def initialize(*args)
    super(*args)
  end


  def blockable_teachers
    return [] if self.program.nil?

    program = self.program
    # get all teachers for specific program type
    teacher_ids = ProgramTypesTeachers.find_all_by_program_type_id(program.program_donation.program_type_id).map { |pts| pts[:teacher_id] }
    program.timings.each {|t|
      # if teacher is available for each of timing specified in the program for the specified center
      teacher_ids &= TeacherSchedule.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").where(['teacher_schedules.start_date <= ? AND teacher_schedules.end_date >= ? AND teacher_schedules.timing_id = ? AND teacher_schedules.state = ? AND centers_teacher_schedules.center_id IS ? AND teacher_schedules.program_type_id IS ?',
                                            program.start_date.to_date, program.end_date.to_date, t.id,
                                            ::TeacherSchedule::STATE_AVAILABLE, program.center_id, program.program_donation.program_type_id]).pluck(:teacher_id)
    }
    teachers = Teacher.find(teacher_ids)
  end


  def blockable_programs
    return [] if self.teacher.nil?
    teacher = self.teacher
    # the list returned here is not a confirmed list, it is a tentative list which might fail validations later
    # TODO - writing the query for confirmed list is too db intensive for now, so skipping it
    # NOTE: We cannot add a teacher once the program has started
    programs = Program.where('center_id IN (?) AND start_date > ? AND state NOT IN (?)', teacher.center_ids, Time.zone.now, ::Program::CLOSED_STATES).order('start_date ASC').all
    blockable_programs = []
    programs.each {|program|
      blockable_programs << program if teacher.can_be_blocked_by?(program)
    }
    blockable_programs
  end


  # Incoming params - params => {"program_id"=>"3", "teacher_id"=>"1"}
  # 1. given the teacher_id, find the schedules relevant for the program_id
  # 2. split the schedule, marking the one against program - with program_id and state
  def block_teacher_schedule!(params)
    program = Program.find(params[:program_id])
    teacher = Teacher.find(params[:teacher_id])
    program.timings.each {|t|
      ts = teacher.teacher_schedules.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").where('teacher_schedules.start_date <= ? AND teacher_schedules.end_date >= ? AND teacher_schedules.timing_id = ? AND teacher_schedules.state = ? AND centers_teacher_schedules.center_id IS ? AND teacher_schedules.program_type_id IS ?',
                                           program.start_date.to_date, program.end_date.to_date, t.id,
                                           ::TeacherSchedule::STATE_AVAILABLE, program.center_id, program.program_donation.program_type_id).readonly(false).first
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
      ts.save!
      # TODO - check if break if correct idea, we should rollback previous change(s) in this loop
      if !ts.errors.empty?
        self.errors[:base] << ts.errors.full_messages
        break
      end
      self.teacher_schedule_id = ts.id
    }
    # This is a hack to store in the activity_log
    self.log_last_activity(current_user, ::TeacherSchedule::STATE_AVAILABLE, ::ProgramTeacherSchedule::STATE_BLOCKED, ::ProgramTeacherSchedule::EVENT_BLOCK)
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

    old_state = ::TeacherSchedule::STATE_UNKNOWN
    teacher_schedules = TeacherSchedule.where('program_id = ? AND teacher_id = ?', self.program_id, self.teacher_id)
    teacher_schedules.each {|ts|
      # 1. update the state of all teacher_schedule(s) for a teacher, and program
      old_state = ts.state
      ts.store_last_update!(self.current_user, ts.state, self.state, trigger)
      ts.state = self.state
      ts.program_id = program_id
      ts.blocked_by_user_id = blocked_by_user_id
      ts.comments = self.comments.nil? ? "" : self.comments
      ts.feedback = self.feedback unless self.feedback.nil?
      ts.save!
      ## TODO - check if break if correct idea, we should rollback previous change(s) in this loop
      if !ts.errors.empty?
        self.errors[:base] << ts.errors.full_messages
        break
      end

      # 2. if they have been marked Available or unavailable, then check if combine_consecutive_slots
      if ((::TeacherSchedule::STATE_PUBLISHED + [::TeacherSchedule::STATE_AVAILABLE_EXPIRED]).include?(ts.state)) && ts.can_combine_consecutive_schedules?
        ts.clear_comments!
        ts.clear_last_update!
        ts.combine_consecutive_schedules!
        # TODO - check if break if correct idea, we should rollback previous change(s) in this loop
        if !ts.save
          self.errors[:base] << ts.errors.full_messages
          break
        end
      end
      # This is a HACK to store to activity log
      self.log_last_activity(self.current_user, old_state, self.state, trigger)
      self.deleted_program_id = self.program_id if program_id.nil?
      self.program_id = program_id
    }
  end

  def can_create?(center_ids = self.program.center_id)
    return true if self.current_user.is? :center_scheduler, :for => :any, :center_id => center_ids
    return false
  end

  def can_update?
    return true if self.current_user.is? :center_scheduler, :center_id => self.program.center_id
    return true if self.current_user == self.teacher.user
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
