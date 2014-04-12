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
      # TODO - add the lambdas for all role and can checks
      transition STATE_ASSIGNED => ::TeacherSchedule::STATE_AVAILABLE #, :if => lambda {|pts| pts.current_user.is? :zonal_coordinator, :center_id => pts.program.center_id}
      transition STATE_BLOCKED => ::TeacherSchedule::STATE_AVAILABLE #, :if => lambda {|pts| pts.current_user.is? :zonal_coordinator, :center_id => pts.program.center_id}
    end
    before_transition any => ::TeacherSchedule::STATE_AVAILABLE, :do => :can_unblock?
#    before_transition STATE_BLOCKED => ::TeacherSchedule::STATE_AVAILABLE, :do => :can_unblock?
    after_transition any => ::TeacherSchedule::STATE_AVAILABLE, :do => :on_available



  end

  def on_available
    ### we will remove the program_id later, during update
  end

  def initialize(*args)
    super(*args)
  end

  # these calls will go in the lambda function, so that relevant menu items can be disabled.
  def can_unblock?
    ### TODO - set validations if user can unblock, CS and SC on venue conditions
    if !self.current_user.is? :zonal_coordinator, :center_id => self.program.center_id
      self.errors[:base] << "Insufficient privileges to update the state."
      false
    else
      true
    end
  end


  # NOTE: ProgramTeacherSchedule is **NOT** inherited from the ActiveRecord class
  def update

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
      if (::TeacherSchedule::STATE_PUBLISHED).include?(ts.state) && ts.combine_consecutive_schedules?
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



end

