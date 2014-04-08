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

  #composed_of :program, mapping: %w(program_id id)
  #composed_of :teacher_schedule, mapping: [ %w(teacher_id teacher_id), %w(schedule_id id), %w(reserving_user_id reserving_user_id) ]

  attr_accessor :teacher_id, :teacher, :reserving_user_id, :program, :program_id, :teacher_schedule, :teacher_schedule_id

  # attr_accessible :program, :program_id, :teacher_id, :reserving_user_id
  # validates :program_id, :teacher_id, :reserving_user_id, :presence => true
  before_save :update_teacher_schedules


  STATE_UNKNOWN  = :unknown
  STATE_AVAILABLE  = :available
  STATE_UNAVAILABLE  = :unavailable
  STATE_BLOCKED  = :blocked
  STATE_ASSIGNED  = :assigned
  STATE_REQUEST_RELEASE  = :request_release
  STATE_IN_CLASS  = :in_class
  STATE_COMPLETED_CLASS  = :completed_class
  STATE_WITHDRAWN  = :withdrawn

  ### TODO -
  # http://www.sitepoint.com/comparing-ruby-background-processing-libraries-delayed-job/
  # Program will be sending four notifications - two on timers, two on user action
  # timer can be set using the delayed action for the program state machine
  ###

  PROCESSABLE_EVENTS = [
      :available, :unavailable, :assigned, :request_release,
      :program_cancelled, :program_dropped, :program_started, :program_completed, :withdraw
  ]

  state_machine :state, :initial => STATE_BLOCKED do
    event :available do
      transition STATE_ASSIGNED => STATE_AVAILABLE, :if => lambda {|pts| pts.is_zonal_coordinator?}, :do => :remove_program_id
      transition STATE_BLOCKED => STATE_AVAILABLE, if: lambda {|pts| pts.can_unblock?}, :do => :remove_program_id
    end

    event :unavailable do
      transition [STATE_BLOCKED] => STATE_ASSIGNED
    end

    event :assigned do
      transition [STATE_BLOCKED] => STATE_ASSIGNED
    end

    event :request_release do
      transition [STATE_BLOCKED] => STATE_ASSIGNED
    end

    event :program_cancelled do
      transition [STATE_BLOCKED] => STATE_ASSIGNED
    end

    event :program_dropped do
      transition [STATE_BLOCKED] => STATE_ASSIGNED
    end

    event :program_started do
      transition [STATE_BLOCKED] => STATE_ASSIGNED
    end

    event :program_completed do
      transition [STATE_BLOCKED] => STATE_ASSIGNED
    end

    event :withdraw do
      transition [STATE_BLOCKED] => STATE_ASSIGNED
    end

    def remove_program_id
      ### TODO - for all teacher schedules for the program, remove the program-id entry
    end

  end

  def is_zonal_coordinator?
    ### TODO - fill is zonal coordinator
  end

  def can_unblock?
    ### TODO - set validations if user can unblock, CS and SC on venue conditions
  end



end

