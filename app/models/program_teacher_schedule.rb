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
  # needed for using form_for
  #extend ActiveModel::Naming
  #include ActiveModel::AttributeMethods

  #composed_of :program, mapping: %w(program_id id)
  #composed_of :teacher_schedule, mapping: [ %w(teacher_id teacher_id), %w(schedule_id id), %w(reserving_user_id reserving_user_id) ]

  attr_accessor :teacher_id, :teacher, :blocked_by_user_id, :program, :program_id, :teacher_schedule, :teacher_schedule_id, :comments

  attr_accessor :current_user, :state

  # attr_accessible :program, :teacher_id, :reserving_user_id
  # validates :program_id, :teacher_id, :reserving_user_id, :presence => true


  #STATE_UNKNOWN  = :unknown
  STATE_UNKNOWN             = 'Unknown'
  STATE_BLOCKED             = 'Blocked'
  STATE_ASSIGNED            = 'Assigned'
  STATE_RELEASE_REQUESTED   = 'Release Requested'
  STATE_IN_CLASS            = 'In Class'
  STATE_COMPLETED_CLASS     = 'Completed Class'
  STATE_WITHDRAWN           = 'Withdrawn'

  CONNECTED_STATES = [STATE_BLOCKED, STATE_RELEASE_REQUESTED, STATE_ASSIGNED, STATE_IN_CLASS]
  FINAL_STATES = [STATE_COMPLETED_CLASS, STATE_WITHDRAWN]


  # Events
  EVENT_BLOCK              = 'Block'
  EVENT_REQUEST_RELEASE    = 'Request Release'
  EVENT_RELEASE            = 'Release'
  EVENT_ASSIGN             = 'Assign'
  EVENT_WITHDRAW           = 'Withdraw'


  PROCESSABLE_EVENTS = [
      EVENT_REQUEST_RELEASE, EVENT_RELEASE, EVENT_WITHDRAW
  ]

  EVENTS_WITH_COMMENTS = [EVENT_RELEASE, EVENT_WITHDRAW, EVENT_REQUEST_RELEASE]
  EVENTS_WITH_FEEDBACK = []


  state_machine :state, :initial => STATE_UNKNOWN do

    event EVENT_BLOCK do
      transition STATE_UNKNOWN => STATE_BLOCKED, :if => lambda {|pts| pts.current_user.is? :center_scheduler, :center_id => pts.program.center_id}
    end

    event EVENT_RELEASE do
      transition STATE_BLOCKED => ::TeacherSchedule::STATE_AVAILABLE, :if => lambda {|pts| pts.current_user.is? :center_scheduler, :center_id => pts.program.center_id}
      transition STATE_ASSIGNED => ::TeacherSchedule::STATE_UNAVAILABLE, :if => lambda {|pts| pts.current_user.is? :sector_coordinator, :center_id => pts.program.center_id}
      transition STATE_RELEASE_REQUESTED => ::TeacherSchedule::STATE_UNAVAILABLE, :if => lambda {|pts| pts.current_user.is? :sector_coordinator, :center_id => pts.program.center_id}
    end
    # move the before transition, privilege part of the check to :if condition of the transition
    before_transition STATE_BLOCKED => ::TeacherSchedule::STATE_AVAILABLE do |pts, transition|
        pts.can_unblock? unless transition.event == ::Program::DROPPED
    end
    before_transition STATE_ASSIGNED => ::TeacherSchedule::STATE_UNAVAILABLE, :do => :can_mark_assign_to_unavailable?
    before_transition STATE_RELEASE_REQUESTED => ::TeacherSchedule::STATE_UNAVAILABLE, :do => :can_approve_release?

    event EVENT_REQUEST_RELEASE do
      transition STATE_BLOCKED => STATE_RELEASE_REQUESTED, :if => lambda {|pts| pts.is_teacher? }
      transition STATE_ASSIGNED => STATE_RELEASE_REQUESTED
    end
    before_transition any => STATE_RELEASE_REQUESTED, :do => :is_teacher?

    # Done
    event ::Program::CANCELLED do
      transition STATE_ASSIGNED => ::TeacherSchedule::STATE_AVAILABLE
    end

    # Done
    event ::Program::DROPPED do
      transition STATE_BLOCKED => ::TeacherSchedule::STATE_AVAILABLE
    end

    # in case the program is already announced, allowing them to change the state
    event EVENT_ASSIGN do
      transition STATE_BLOCKED => STATE_ASSIGNED, :if => lambda {|pts| pts.program.is_announced? && pts.program.is_active? }
    end
    after_transition STATE_BLOCKED => STATE_ASSIGNED, :do => :if_program_started!

    # Done
    event ::Program::ANNOUNCED do
      transition STATE_BLOCKED => STATE_ASSIGNED
    end

    # Done
    event ::Program::STARTED do
      transition STATE_ASSIGNED => STATE_IN_CLASS
    end

    # Done
    event ::Program::FINISHED do
      transition STATE_IN_CLASS => STATE_COMPLETED_CLASS
    end

    # Done
    event EVENT_WITHDRAW do
      transition STATE_IN_CLASS => STATE_WITHDRAWN, :if => lambda {|pts| pts.current_user.is? :zonal_coordinator, :center_id => pts.program.center_id}
    end
    before_transition STATE_IN_CLASS => STATE_WITHDRAWN, :do => :can_withdraw?


  end

  def if_program_started!
    self.send(::Program::STARTED) if self.program.is_started?
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

    self.errors[:base] << "Insufficient privileges to update the state."
    false
  end

  def can_approve_release?
    if !self.current_user.is? :sector_coordinator, :center_id => self.program.center_id
      self.errors[:base] << "Insufficient privileges to update the state."
      return false
    end

    if ((self.program.no_of_teachers_connected <= self.program.minimum_no_of_teacher) && self.program.venue_approved?)
      self.errors[:base] << "Cannot remove teacher. Number of teachers needed will become less than the number needed. Please add another teacher and try again."
      return false
    end

    true
  end


  def can_mark_assign_to_unavailable?
    if !self.current_user.is? :sector_coordinator, :center_id => self.program.center_id
      self.errors[:base] << "Insufficient privileges to update the state."
      return false
    end

    if self.program.no_of_teachers_connected <= self.program.minimum_no_of_teacher
      self.errors[:base] << "Cannot remove teacher. Number of teachers needed will become less than the number needed. Please add another teacher and try again."
      return false
    end
    true
  end

  def can_withdraw?
    if !self.current_user.is? :zonal_coordinator, :center_id => self.program.center_id
      self.errors[:base] << "Insufficient privileges to update the state."
      return false
    end

    if self.program.no_of_teachers_connected <= self.program.minimum_no_of_teacher
      self.errors[:base] << "Cannot remove teacher. Number of teachers needed will become less than the number needed. Please add another teacher and try again."
      false
    end
    true
  end

  def is_teacher?
    if self.current_user.id != self.teacher_id
      self.errors[:base] << "Insufficient privileges to update the state."
      false
    end
    true
  end


  def initialize(*args)
    super(*args)
  end



  # NOTE: ProgramTeacherSchedule is **NOT** using ActiveRecord class functions like save
  def update
    # if the state was updated to ::TeacherSchedule::STATE_AVAILABLE or ::TeacherSchedule::STATE_UNAVAILABLE
    if (::TeacherSchedule::STATE_PUBLISHED).include?(self.state)
      program_id = nil
      blocked_by_user_id = nil
    else
      program_id = self.program_id
      blocked_by_user_id = self.blocked_by_user_id
    end
    # Cannot update using sql because we need to combine the slots also
    # TeacherSchedule.where('program_id = ? AND teacher_id = ?', self.program.id, self.teacher_id).update_all(
    #     {:state => self.state, :program_id => program_id, :blocked_by_user_id => self.blocked_by_user_id})

    teacher_schedules = TeacherSchedule.where('program_id = ? AND teacher_id = ?', self.program_id, self.teacher_id)
    teacher_schedules.each {|ts|
      # 1. update the state of all teacher_schedule(s) for a teacher, and program.
      ts.state = self.state
      ts.program_id = program_id
      ts.blocked_by_user_id = blocked_by_user_id
      ts.save(:validate => false)
      ## TODO - check if break if correct idea, we should rollback previous change(s) in this loop
      if !ts.errors.empty?
        self.errors[:base] << ts.errors.full_messages
        break
      end

      # 2. if they have been marked Available or unavailable, then check if combine_consecutive_slots
      if ((::TeacherSchedule::STATE_PUBLISHED).include?(ts.state)) && ts.combine_consecutive_schedules?
        ts.combine_consecutive_schedules
        # TODO - check if break if correct idea, we should rollback previous change(s) in this loop
        if !ts.save
          self.errors[:base] << ts.errors.full_messages
          break
        end
      end
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
end

