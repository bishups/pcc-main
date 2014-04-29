# == Schema Information
#
# Table name: programs
#
#  id                  :integer          not null, primary key
#  name                :string(255)
#  description         :text
#  center_id           :string(255)
#  program_type_id     :integer
#  proposer_id         :integer
#  manager_id          :integer
#  state               :string(255)
#  start_date          :datetime
#  end_date            :datetime
#  slot                :string(255)
#  announce_program_id :string(255)
#  venue_schedule_id   :integer
#  kit_schedule_id     :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class Program < ActiveRecord::Base
  include CommonFunctions

  validates :start_date, :presence => true
#  validates :end_date, :presence => true
  validates :center_id, :presence => true

  belongs_to :proposer, :class_name => "User" #, :foreign_key => "rated_id"
  attr_accessible :proposer_id, :proposer

  validates :proposer_id, :presence => true
  validates_with ProgramValidator, :on => :create

  attr_accessor :current_user
  attr_accessible :name, :program_type_id, :start_date, :center_id, :end_date, :feedback

  before_create :assign_dates!

  belongs_to :center
  belongs_to :program_type
  has_many :venue_schedules
  attr_accessible :venue_schedules, :venue_schedule_ids
  has_many :kit_schedules
  attr_accessible :kit_schedules, :kit_schedule_ids
  has_many :teacher_schedules
  attr_accessible :teacher_schedules, :teacher_schedule_ids
  has_many :teachers, :through => :teacher_schedules
  attr_accessible :teachers, :teacher_ids

  has_and_belongs_to_many :timings, :join_table => :programs_timings
  attr_accessible :timing_ids, :timings

  belongs_to :last_updated_by_user, :class_name => User
  attr_accessible :last_update, :last_updated_at

  attr_accessor :comment_category
  attr_accessible :comment_category

  STATE_UNKNOWN       = "Unknown"
  STATE_PROPOSED      = "Proposed"
  STATE_ANNOUNCED     = "Announced"
  STATE_REGISTRATION_OPEN = "Registration Open"
  STATE_DROPPED       = "Dropped"
  STATE_CANCELLED     = "Cancelled"
  STATE_IN_PROGRESS   = "In Progress"
  STATE_CONDUCTED     = "Conducted"
  STATE_TEACHER_CLOSED = "Teacher Closed"
  STATE_ZAO_CLOSED    = "ZAO Closed"
  STATE_CLOSED        = "Closed"
  STATE_EXPIRED       = "Expired"

  FINAL_STATES = [STATE_DROPPED, STATE_CANCELLED, STATE_CLOSED, STATE_EXPIRED]
  CLOSED_STATES = (FINAL_STATES + [STATE_CONDUCTED, STATE_TEACHER_CLOSED, STATE_ZAO_CLOSED])


  EVENT_PROPOSE       = "Propose"
  EVENT_ANNOUNCE      = "Announce"
  EVENT_REGISTRATION_OPEN = "Registration Open"
  EVENT_START         = "Start"
  EVENT_FINISH        = "Finish"
  EVENT_CLOSE         = "Close"
  EVENT_DROP          = "Drop"
  EVENT_CANCEL        = "Cancel"
  EVENT_TEACHER_CLOSE = "Teacher Close"
  EVENT_ZAO_CLOSE = "ZAO Close"
  EVENT_EXPIRE = "Expire"

  PROCESSABLE_EVENTS = [
      EVENT_ANNOUNCE, EVENT_REGISTRATION_OPEN, EVENT_CLOSE, EVENT_CANCEL, EVENT_DROP, EVENT_TEACHER_CLOSE, EVENT_ZAO_CLOSE
  ]

  INTERNAL_NOTIFICATIONS = [EVENT_START, EVENT_FINISH, EVENT_EXPIRE]

  EVENTS_WITH_COMMENTS = [EVENT_DROP, EVENT_CANCEL, EVENT_ZAO_CLOSE]
  EVENTS_WITH_FEEDBACK = [EVENT_TEACHER_CLOSE]

  ### TODO -
  # http://www.sitepoint.com/comparing-ruby-background-processing-libraries-delayed-job/
  # Program will be sending four notifications - two on timers, two on user action
  # timer can be set using the delayed action for the program state machine
  ###
  # these are program events which are sent to other state machines
  # adding program in the string, to avoid clash with any other event string in other state machines
  CANCELLED  = 'Program Cancelled'    # -> after_transition any => STATE_CANCELLED
  DROPPED    = 'Program Dropped'      # -> after_transition any => STATE_DROPPED
  ANNOUNCED  = 'Program Announced'    # -> after_transition any => STATE_ANNOUNCED
  STARTED    = 'Program Started'      # -> on timer notification, provided program still in valid state (on receiving modules will independently validate their state before processing this event)
  FINISHED   = 'Program Finished'     # -> on timer notification, provided program still in valid state (on receiving modules will independently validate their state before processing this event)
  #CLOSED     = 'Program Closed'       # -> after_transition any => STATE_CLOSED
  NOTIFICATIONS = [
      CANCELLED, DROPPED, ANNOUNCED, STARTED, FINISHED
  ]


  # timing_ids = program.timing_ids.class == Array ? program.timing_ids : [program.timing_ids]
  # given a program, returns a relation with other non-overlapping program(s)
  scope :available, lambda { |program| Program.joins("JOIN programs_timings ON programs.id = programs_timings.program_id").where('(programs.start_date NOT BETWEEN ? AND ?) AND (programs.end_date NOT BETWEEN ? AND ?) AND NOT (programs.start_date <= ? AND programs.end_date >= ?) AND programs_timings.timing_id NOT IN (?) AND programs.id IS NOT ? ',
                                                                             program.start_date, program.end_date, program.start_date, program.end_date, program.start_date, program.end_date, program.timing_ids, program.id) }

  # given a program, returns a relation with other overlapping program(s)
  scope :overlapping, lambda { |program| Program.joins("JOIN programs_timings ON programs.id = programs_timings.program_id").where('((programs.start_date BETWEEN ? AND ?) OR (programs.end_date BETWEEN ? AND ?) OR  (programs.start_date <= ? AND programs.end_date >= ?)) AND programs_timings.timing_id IN (?) AND programs.id IS NOT ? ',
                                                                               program.start_date, program.end_date, program.start_date, program.end_date, program.start_date, program.end_date, program.timing_ids, program.id) }

  # given a program, returns a relation with other overlapping program(s)
  scope :overlapping_date_time, lambda { |start_date, end_date| Program.where('((programs.start_date BETWEEN ? AND ?) OR (programs.end_date BETWEEN ? AND ?) OR  (programs.start_date <= ? AND programs.end_date >= ?))',
                                                                                                                                   start_date, end_date, start_date, end_date, start_date, end_date) }

  def initialize(*args)
    super(*args)
  end

  state_machine :state, :initial => STATE_UNKNOWN do

    event EVENT_PROPOSE do
      transition STATE_UNKNOWN => STATE_PROPOSED, :if => lambda {|t| t.can_create? }
    end
    before_transition STATE_UNKNOWN => STATE_PROPOSED, :do => :can_create?
    after_transition STATE_UNKNOWN => STATE_PROPOSED, :do => :fill_proposer_id!

    event EVENT_ANNOUNCE do
      transition STATE_PROPOSED => STATE_ANNOUNCED, :if => lambda {|p| p.can_announce?}
    end
    before_transition any => STATE_ANNOUNCED, :do => :can_announce?
    after_transition any => STATE_ANNOUNCED, :do => :on_announce

    event EVENT_DROP do
      transition STATE_PROPOSED => STATE_DROPPED, :if => lambda {|p| p.current_user.is? :center_scheduler, :center_id => p.center_id}
    end
    before_transition any => STATE_DROPPED, :do => :can_drop?
    after_transition any => STATE_DROPPED, :do => :on_drop

    event EVENT_REGISTRATION_OPEN do
      transition STATE_ANNOUNCED => STATE_REGISTRATION_OPEN, :if => lambda {|p| p.current_user.is? :center_treasurer, :center_id => p.center_id}
    end
    before_transition any => STATE_REGISTRATION_OPEN, :do => :can_open_registration?

    event EVENT_START do
      transition [STATE_ANNOUNCED, STATE_REGISTRATION_OPEN] => STATE_IN_PROGRESS
    end
    after_transition any => STATE_IN_PROGRESS, :do => :on_start

    event EVENT_EXPIRE do
      transition STATE_PROPOSED => STATE_EXPIRED
    end

    event EVENT_FINISH do
      transition STATE_IN_PROGRESS => STATE_CONDUCTED
    end
    after_transition any => STATE_CONDUCTED, :do => :on_finish

    event EVENT_TEACHER_CLOSE do
      transition STATE_CONDUCTED => STATE_TEACHER_CLOSED, :if => lambda {|p| p.is_teacher?}
    end
    before_transition any => STATE_TEACHER_CLOSED, :do => :can_teacher_close?

    event EVENT_ZAO_CLOSE do
      transition STATE_TEACHER_CLOSED => STATE_ZAO_CLOSED, :if => lambda {|p| p.is_zao? }
    end
    before_transition any => STATE_ZAO_CLOSED, :do => :can_zao_close?

    event EVENT_CLOSE do
      transition STATE_ZAO_CLOSED => STATE_CLOSED, :if => lambda {|p| p.current_user.is? :center_coordinator, :center_id => p.center_id}
    end
    before_transition any => STATE_CLOSED, :do => :can_close?
    # TODO - enable or disable the button based on whether conditions are met

    event EVENT_CANCEL do
      transition [STATE_ANNOUNCED, STATE_REGISTRATION_OPEN] => STATE_CANCELLED, :if => lambda {|p| p.current_user.is? :zonal_coordinator, :center_id => p.center_id }
    end
    before_transition any => STATE_CANCELLED, :do => :can_cancel?
    after_transition any => STATE_CANCELLED, :do => :on_cancel

    # check for comments, before any transition
    before_transition any => any do |object, transition|
      if EVENTS_WITH_COMMENTS.include?(transition.event) && !object.has_comments?
        return false
      end
      if EVENTS_WITH_FEEDBACK.include?(transition.event) && !object.has_feedback?
        return false
      end
    end

    # send notifications, after any transition
    after_transition any => any do |object, transition|
      object.store_last_update!(object.current_user, transition.from, transition.to, transition.event)
      object.notify(transition.from, transition.to, transition.event, object.center_id)
    end

  end

  def fill_proposer_id!
    self.proposer = current_user
  end

  def reloaded?
    self.reload
    return true
  rescue ActiveRecord::RecordNotFound
    # TODO - check if to log any error
    return false
  end

  def trigger_program_start
    return if !self.reloaded?
    if [STATE_ANNOUNCED, STATE_REGISTRATION_OPEN].include?(self.state)
      self.send(EVENT_START)
      self.save if self.errors.empty?
    end
    if [STATE_PROPOSED].include?(self.state)
      self.send(EVENT_EXPIRE)
      self.save if self.errors.empty?
    end
  end

  def trigger_program_finish
    return if !self.reloaded?
    if [STATE_IN_PROGRESS].include?(self.state)
      self.send(EVENT_FINISH)
      self.save if self.errors.empty?
    end
  end

  def can_announce?
    if ready_for_announcement?
      return true if self.current_user.is? :center_scheduler, :center_id => self.center_id
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    else
      self.errors[:base] << "Program cannot be announced yet."
      return false
    end
  end

  def on_announce
    self.generate_program_id!
    self.notify_all(ANNOUNCED)
    # start the timer for start of class notification
    self.delay(:run_at => self.start_date).trigger_program_start
  end

  def can_open_registration?
    return true if (self.current_user.is? :center_treasurer, :center_id => self.center_id)
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def can_drop?
    if (self.current_user.is? :sector_coordinator, :center_id => self.center_id)
      if self.venue_approved?
        self.errors[:base] << "Cannot drop program. Venue linked to the program has already gone for payment request."
        return false
      end
      return true
    end

    if (self.current_user.is? :center_scheduler, :center_id => self.center_id)
      if self.venue_approval_requested?
        self.errors[:base] << "Cannot drop program. Venue linked to the program has already gone for sector coordinator approval."
        return false
      end
      return true
    end

    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end


  def on_drop
    self.notify_schedules(DROPPED)
  end

  def on_start
    self.notify_schedules(STARTED)
    # start the timer for close of class notification
    self.delay(:run_at => self.end_date).trigger_program_finish
  end

  def on_finish
    self.notify_all(FINISHED)
  end

  def is_active?
    !(::Program::CLOSED_STATES.include?(self.state))
  end

  def can_teacher_close?
    unless is_teacher?
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    end
    return true
  end

  def can_zao_close?
    return false unless self.is_zao?

    unless account_closed?
      self.errors[:base] << "Cannot ZAO Close program, accounts for program are not closed."
      return false
    end

    unless participant_data_entered?
      self.errors[:base] << "Cannot ZAO Close program, participant data for program has not been entered."
      return false
    end
    return true
  end



  def account_closed?
    # TODO - need to implement account_closed??
    return true
  end

  def participant_data_entered?
    # TODO - need to implement participant_data_entered?
    return true
  end


  def is_zao?
    return true if self.current_user.is? :zao, :center_id => self.center_id
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end


  def can_close?
    if ready_for_close?
      return true if self.current_user.is? :center_coordinator, :center_id => self.center_id
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    else
      self.errors[:base] << "Program cannot be closed yet."
      return false
    end
  end

  def can_cancel?
    return true if (self.current_user.is? :zonal_coordinator, :center_id => self.center_id)
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def on_cancel
    self.notify_all(CANCELLED)
    # TODO - cancel the timer for start of the class, no need for now, we will just ignore it once the timer comes
  end

  def friendly_name
    ("(%s) %s (%s)" % [self.start_date.strftime('%d %B %Y'), self.center.name, self.program_type.name])
  end

  def is_announced?
    self.announce_program_id && !self.announce_program_id.empty?
  end

  def in_progress?
    self.state == STATE_IN_PROGRESS
  end

  def generate_program_id!
    self.announce_program_id = ("%s %s %d" % 
      [self.center.name, self.start_date.strftime('%B%Y'), self.id]
    ).parameterize
    #self.save!
  end
  
  def proposer
    ::User.find(self.proposer_id)
  end

  def venue_connected?
    !self.venue_schedules.empty?
  end

  def notify_all(event)
    # send the event to each of the state machines
    # ideally we can register the state machine and the specific callback they want to be called
    self.teacher_schedules.each{|ts|
      ts.current_user = self.current_user
      ts.on_program_event(event)
    }
    self.venue_schedules.each{|vs|
      vs.current_user = self.current_user
      vs.on_program_event(event)
    }
    self.kit_schedules.each{|ks|
      ks.current_user = self.current_user
      ks.on_program_event(event)
    }
  end


  #def connect_venue(venue)
  #  self.venue_schedule_id = venue.id
  #  self.save!
  #end

  #def disconnect_venue(venue)
  #  self.venue_schedule_id = nil
  #  self.save!
  #end


  #def connect_kit(kit)
  #  self.kit_schedule_id = kit.id
  #  self.save
  #end

  #def disconnect_kit(kit)
  #  self.kit_schedule_id = nil
  #  self.save!
  #end


  def blockable_venues
    # the list returned here is not a confirmed list, it is a tentative list which might fail validations later
    # TODO - writing the query for confirmed list is too db intensive for now, so skipping it
    Venue.joins("JOIN centers_venues ON venues.id = centers_venues.venue_id").where('centers_venues.center_id = ?', self.center_id).order('LOWER(venues.name) ASC')
  end

  def blockable_kits
    # the list returned here is not a confirmed list, it is a tentative list which might fail validations later
    # TODO - writing the query for confirmed list is too db intensive for now, so skipping it
    Kit.joins("JOIN centers_kits ON kits.id = centers_kits.kit_id").where('centers_kits.center_id = ?', self.center_id)
  end

  def assign_dates!
    self.end_date = self.start_date + (self.program_type.no_of_days.to_i.days - 1.day)
    @program.update_attributes :start_date => @program.start_date_time, :end_date => @program.end_date_time  end



  def no_of_teachers_connected_or_conducted
    return 0 if !self.teacher_schedules
    self.teacher_schedules.where('state IN (?) ', (::ProgramTeacherSchedule::CONNECTED_STATES + [::ProgramTeacherSchedule::STATE_COMPLETED_CLASS])).group('teacher_id').length
  end

  def no_of_teachers_connected
    return 0 if !self.teacher_schedules
    self.teacher_schedules.where('state IN (?) ', ::ProgramTeacherSchedule::CONNECTED_STATES).group('teacher_id').length
  end

  def teachers_connected
    return 0 if !self.teacher_schedules
    self.teacher_schedules.where('state IN (?) ', ::ProgramTeacherSchedule::CONNECTED_STATES).group('teacher_id')
#    self.teacher_schedules.where('state IN (?) ', ::ProgramTeacherSchedule::CONNECTED_STATES).group('teacher_id').length
  end

  def teachers_conducted_class
    return 0 if !self.teacher_schedules
    self.teacher_schedules.where('state IN (?) ', [::ProgramTeacherSchedule::STATE_COMPLETED_CLASS]).group('teacher_id')
#    self.teacher_schedules.where('state IN (?) ', ::ProgramTeacherSchedule::CONNECTED_STATES).group('teacher_id').length
  end

  def minimum_no_of_teacher
    self.program_type.minimum_no_of_teacher
  end

  def minimum_teachers_connected?
    self.no_of_teachers_connected >= self.minimum_no_of_teacher
  end

  def is_teacher?
    self.teacher_schedules.each { |ts|
      if ((::ProgramTeacherSchedule::CONNECTED_STATES + [::ProgramTeacherSchedule::STATE_COMPLETED_CLASS]).include?(ts.state) && ts.teacher.user == self.current_user)
        return true
      end
    }
    return false
  end

  def no_of_kits_connected
    return 0 if !self.kit_schedules
    self.kit_schedules.where('state IN (?)', ::KitSchedule::CONNECTED_STATES).count
  end

  def no_of_kits_assigned
    return 0 if !self.kit_schedules
    self.kit_schedules.where('state IN (?)', ::KitSchedule::ASSIGNED_STATES).count
  end

  def no_of_venues_connected
    return 0 if !self.venue_schedules
    self.venue_schedules.where('state IN (?)', ::VenueSchedule::CONNECTED_STATES).count
  end

  def no_of_venues_blocked
    return 0 if !self.venue_schedules
    self.venue_schedules.where('state IN (?)', ::VenueSchedule::BLOCKED_STATES).count
  end

  def no_of_venues_paid
    return 0 if !self.venue_schedules
    self.venue_schedules.where('state IN (?)', ::VenueSchedule::PAID_STATES).count
  end

  def start_date_time
    timing = Timing.joins("JOIN programs_timings ON timings.id = programs_timings.timing_id").where('programs_timings.program_id = ?', self.id).order('start_time ASC').first
    self.start_date.advance(:hours => timing.start_time.hour, :minutes => timing.start_time.min, :seconds => timing.start_time.sec)
  end

  def end_date_time
    timing = Timing.joins("JOIN programs_timings ON timings.id = programs_timings.timing_id").where('programs_timings.program_id = ?', self.id).order('end_time DESC').first
    self.end_date.advance(:hours => timing.end_time.hour, :minutes => timing.end_time.min, :seconds => timing.end_time.sec)
  end

  def venue_approval_requested?
    self.venue_schedules.each { |vs|
      return true if vs.approval_requested?
    }
    return false
  end

  def venue_approved?
    self.venue_schedules.each { |vs|
      return true if vs.approved?
    }
    return false
  end

  def ready_for_close?
    # TODO - add condition here that teacher adds program feedback,
    if (self.no_of_venues_connected > 0)
      self.errors[:base] << "Cannot close program, linked venue is not closed. Please close it and try again."
      return false
    end

    if (self.no_of_kits_connected > 0)
      self.errors[:base] << "Cannot close program, linked kit is not closed. Please close it and try again."
      return false
    end

    if (self.no_of_teachers_connected > 0)
      self.errors[:base] << "Cannot close program, teacher(s) are still linked to the program."
      return false
    end

    return true
  end

  def ready_for_announcement?
    return false unless self.no_of_venues_paid > 0
    return false unless self.no_of_kits_connected > 0
    return false unless self.minimum_teachers_connected?
    return true
  end


  def can_view?
    return true if self.current_user.is? :any, :center_id => self.center_id
    return false
  end

  # Usage --
  # 1. can_create?
  # 2. can_create? :any => true
  # if note specific default value of :any is false
  def can_create?(options={})
    if options.has_key?(:any) && options[:any] == true
      center_ids = []
    else
      center_ids = self.center_id
    end

    return true if self.current_user.is? :center_scheduler, :center_id => center_ids
    return false
  end

  def can_update?
    return true if self.current_user.is? :center_scheduler, :center_id => self.center_id
    return true if self.current_user.is? :center_treasurer, :center_id => self.center_id
    return false
  end
end
