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

class ProgramTeacherSchedule

  #composed_of :program, mapping: %w(program_id id)
  #composed_of :teacher_schedule, mapping: [ %w(teacher_id teacher_id), %w(schedule_id id), %w(reserving_user_id reserving_user_id) ]

  attr_accessor :teacher_id, :teacher, :blocked_by_user_id, :program, :program_id, :teacher_schedule, :teacher_schedule_id

  # attr_accessible :program, :teacher_id, :reserving_user_id
  # validates :program_id, :teacher_id, :reserving_user_id, :presence => true


  #STATE_UNKNOWN  = :unknown
  STATE_BLOCKED             = 'Blocked'
  STATE_ASSIGNED            = 'Assigned'
  STATE_REQUESTED_RELEASE   = 'Requested Release'
  STATE_IN_CLASS            = 'In Class'
  STATE_COMPLETED_CLASS     = 'Completed Class'
  STATE_WITHDRAWN           = 'Withdrawn'

  ### TODO -
  # http://www.sitepoint.com/comparing-ruby-background-processing-libraries-delayed-job/
  # Program will be sending four notifications - two on timers, two on user action
  # timer can be set using the delayed action for the program state machine
  ###
  EVENT_AVAILABLE          = 'Available'
  EVENT_UNAVAILABLE        = 'Not Available'
  EVENT_ASSIGN             = 'Assign'
  EVENT_REQUEST_RELEASE    = 'Request Release'
  EVENT_PROGRAM_CANCELLED  = 'Program Cancelled'
  EVENT_PROGRAM_DROPPED    = 'Program Dropped'
  EVENT_PROGRAM_STARTED    = 'Program Started'
  EVENT_PROGRAM_COMPLETED  = 'Program Completed'
  EVENT_WITHDRAW           = 'Withdraw'


  PROCESSABLE_EVENTS = [
      EVENT_AVAILABLE, EVENT_UNAVAILABLE, EVENT_ASSIGN, EVENT_REQUEST_RELEASE,
      EVENT_PROGRAM_CANCELLED, EVENT_PROGRAM_DROPPED, EVENT_PROGRAM_STARTED, EVENT_PROGRAM_COMPLETED, EVENT_WITHDRAW
  ]

  state_machine :state, :initial => STATE_BLOCKED do
    event EVENT_AVAILABLE do
      transition STATE_ASSIGNED => ::TeacherSchedule::STATE_AVAILABLE, :if => lambda {|pts| pts.is_zonal_coordinator?}
      transition STATE_BLOCKED => ::TeacherSchedule::STATE_AVAILABLE, if: lambda {|pts| pts.can_unblock?}
    end
    after_transition any => ::TeacherSchedule::STATE_AVAILABLE do |program_teacher_schedule, transition|
      program_teacher_schedule.program_id = 0
    end



  end

  def initialize(*args)
    super(*args)
  end

  def remove_program_id
    ### TODO - for all teacher schedules for the program, remove the program-id entry
  end

  def is_zonal_coordinator?
    ### TODO - fill is zonal coordinator
  end

  def can_unblock?
    ### TODO - set validations if user can unblock, CS and SC on venue conditions
  end


  # NOTE: ProgramTeacherSchedule is **NOT** inherited from the ActiveRecord class
  def save
    error = []
    # 1. update the state of all teacher_schedule(s) for a teacher, and program.
    teacher_schedules = TeacherSchedule.find(self.teacher_schedule_id).where('program_id = ?', self.program.id)
    teacher_schedules.each {|ts|
      ts.state = self.state
      ts.program_id = self.program_id
      ts.blocked_by_user_id = self.blocked_by_user_id
      ts.save(:validate => false)
      # TODO - check if break if correct idea, we should rollback previous change(s) in this loop
      if !ts.errors.empty?
        error << ts.errors.full_messages
        break
      end

      # 2. if they have been marked Available or unavailable, then check if combine_consecutive_slots
      if (::TeacherSchedule::STATE_PUBLISHED).include?(ts.state) && ts.combine_consecutive_schedules?
        ts.combine_consecutive_schedules
        # TODO - check if break if correct idea, we should rollback previous change(s) in this loop
        if !ts.save
          error << ts.errors.full_messages
          break
        end
      end

    }
    error
  end



end

