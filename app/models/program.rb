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

  has_many :activity_logs, :as => :model, :inverse_of => :model
  has_many :notification_logs, :as => :model, :inverse_of => :model

  belongs_to :program_donation
  attr_accessible :program_donation, :program_donation_id

  validates :name, :start_date, :center_id, :program_donation_id, :presence => true
  validates :timings, :presence => true, :unless => :residential?
  validates :intro_timings, :presence => true, :if => :has_intro?
  validate  :intro_timings_subset?, :if => :has_intro?
#  validates :start_date, :center_id, :name, :program_donation_id, :timings, :presence => true
#  validates :end_date, :presence => true

  belongs_to :proposer, :class_name => "User" #, :foreign_key => "rated_id"
  attr_accessible :proposer_id, :proposer, :capacity

  validates :proposer_id, :presence => true
  validates_with ProgramValidator, :on => :create

  attr_accessor :current_user
  attr_accessible :name, :start_date, :center_id, :end_date, :feedback, :pid, :announced
  attr_accessible :announced_locality, :timing_str, :announced_timing, :timing_str

  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  #
  # announced_timing <-- for E-Media, to be published on website
  #
  # for Uyir Nokkam e.g, --
  # "(4 batches): 9:30am - 10:30am OR 9:30am - 10:30am OR 9:30am - 10:30am OR 9:30am - 10:30am"
  #
  # for IE e.g, ---
  # "(intro)\n"
  # "Wed 7 Jan: 6:00am - 7:15am OR 10:00am - 11:15am OR 6:00pm - 7:15pm\n"
  # "(session)\n"
  # "Wed 7 Jan: 7:15am - 9:00am OR 11:15am - 1:00pm OR 7:15pm - 9:00pm\n"
  # "Thu-Tue (3 batches): 6:00am - 9:00am OR 10:00am - 1:00pm OR 6:00pm - 9:00pm\n"
  # "Sun 11 Jan: Full day\n"
  #
  # for BSP e.g, ---
  # "Arrive by: 4pm on 17th\n"
  # "Program ends: 6:30pm on 20th"
  #
  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  #
  # timing_str <-- used internally for displaying timings
  #
  # -----------------
  # Before Announcing
  # -----------------
  # for Uyir Nokkam e.g, --
  # "Morning (6am - 10am), Afternoon (10am - 2pm), Evening (2pm - 6pm), Night (6pm - 10pm)"
  # for IE e.g, --
  # "(Intro) Morning (6am - 10am), Night(6pm - 10pm); (Session) Morning (6am - 10am), Afternoon (10am - 2pm), Night (6pm - 10pm)"
  # for BSP e.g, --
  # "Starts on 2nd at 2:00pm. Ends on 6th by 6:00pm"
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
  #
  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

  validates :announced_locality, :length => { :maximum => 120}

  before_validation :assign_dates!, :on => :create

  belongs_to :center

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

  has_and_belongs_to_many :intro_timings, :join_table => :programs_intro_timings, :class_name => "Timing"
  attr_accessible :intro_timing_ids, :intro_timings

  has_and_belongs_to_many :date_timings, :join_table => :programs_date_timings
  attr_accessible :date_timing_ids, :date_timings

  belongs_to :last_updated_by_user, :class_name => User
  attr_accessible :last_update, :last_updated_at

  attr_accessor :comment_category
  attr_accessible :comment_category

  attr_accessible :contact_phone, :contact_email


  #attr_accessor :start_time_1, :end_time_1, :start_time_2, :end_time_2, :start_time_3, :end_time_3, :start_time_4, :end_time_4
  attr_accessor :first_day_timing_id, :last_day_timing_id
  attr_accessible :first_day_timing_id, :last_day_timing_id

  attr_accessor :session_time, :intro_time

  STATE_UNKNOWN       = "Unknown"
  STATE_PROPOSED      = "Proposed"
  STATE_ANNOUNCED     = "Announced"
  STATE_DROPPED       = "Dropped"
  STATE_CANCELLED     = "Cancelled"
  STATE_REGISTRATION_CLOSED = "Registration Closed"
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
  EVENT_START         = "Start"
  EVENT_CLOSE_REGISTRATION = "Close Registration"
  EVENT_REGISTRATION_CLOSE_TIMEOUT = "Registration Close Timeout"
  EVENT_FINISH        = "Finish"
  EVENT_CLOSE         = "Close"
  EVENT_DROP          = "Drop"
  EVENT_CANCEL        = "Cancel"
  EVENT_TEACHER_CLOSE = "Teacher Close"
  EVENT_ZAO_CLOSE = "ZAO Close"
  EVENT_EXPIRE = "Expire"

  PROCESSABLE_EVENTS = [
      EVENT_ANNOUNCE, EVENT_CLOSE, EVENT_CANCEL, EVENT_DROP, EVENT_TEACHER_CLOSE, EVENT_ZAO_CLOSE, EVENT_CLOSE_REGISTRATION
  ]

  INTERNAL_NOTIFICATIONS = [EVENT_START, EVENT_FINISH, EVENT_EXPIRE, EVENT_REGISTRATION_CLOSE_TIMEOUT]

  EVENTS_WITH_COMMENTS = [EVENT_DROP, EVENT_CANCEL, EVENT_ZAO_CLOSE, EVENT_CLOSE_REGISTRATION]
  EVENTS_WITH_FEEDBACK = [EVENT_TEACHER_CLOSE]

  ###
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
  EXPIRED    = 'Program Expired'      # -> on timer notification, provided program still in valid state (on receiving modules will independently validate their state before processing this event)
  FINISHED   = 'Program Finished'     # -> on timer notification, provided program still in valid state (on receiving modules will independently validate their state before processing this event)
  #CLOSED     = 'Program Closed'       # -> after_transition any => STATE_CLOSED
  NOTIFICATIONS = [
      CANCELLED, DROPPED, ANNOUNCED, STARTED, EXPIRED, FINISHED
  ]


  # timing_ids = program.timing_ids.class == Array ? program.timing_ids : [program.timing_ids]

  # given a program, returns a relation with other overlapping program(s)
  #scope :overlapping, lambda { |program| Program.joins("JOIN programs_timings ON programs.id = programs_timings.program_id").where('((programs.start_date BETWEEN ? AND ?) OR (programs.end_date BETWEEN ? AND ?) OR  (programs.start_date <= ? AND programs.end_date >= ?)) AND programs_timings.timing_id IN (?) AND (programs.id != ? OR ? IS NULL) ',
  #                                                                             program.start_date, program.end_date, program.start_date, program.end_date, program.start_date, program.end_date, program.timing_ids, program.id, program.id) }

# given a program, returns a relation with all overlapping program(s) (including itself)
  #scope :all_overlapping, lambda { |program| Program.joins("JOIN programs_timings ON programs.id = programs_timings.program_id").where('((programs.start_date BETWEEN ? AND ?) OR (programs.end_date BETWEEN ? AND ?) OR  (programs.start_date <= ? AND programs.end_date >= ?)) AND programs_timings.timing_id IN (?)',
  #
  #                                                                                                                                    program.start_date, program.end_date, program.start_date, program.end_date, program.start_date, program.end_date, program.timing_ids) }

  # given a program, returns a relation with other overlapping program(s)
  scope :overlapping_date_time, lambda { |start_date, end_date| Program.where('((programs.start_date BETWEEN ? AND ?) OR (programs.end_date BETWEEN ? AND ?) OR  (programs.start_date <= ? AND programs.end_date >= ?))',
                                                                              start_date, end_date, start_date, end_date, start_date, end_date) }

  ### program_date_timings
  # given a program, returns a relation with other overlapping program(s)
  # NOTE: initiation day for same program type are allowed to overlap (i.e allowing scope for combined initiation day for multiple programs)
  scope :overlapping, lambda { |program| Program.
      joins("JOIN program_donations ON programs.program_donation_id = program_donations.id").
      joins("JOIN program_types ON program_donations.program_type_id = program_types.id").
      joins("JOIN programs_date_timings ON programs.id = programs_date_timings.program_id").
      joins("JOIN date_timings ON programs_date_timings.date_timing_id = date_timings.id").
      where('programs_date_timings.date_timing_id IN (?) AND (programs.id != ? OR ? IS NULL) AND NOT (program_types.id = ? AND date_timings.date IN (?))',
      program.date_timing_ids, program.id, program.id,
      program.program_donation.program_type.id, program.program_donation.program_type.common_days.map{|d| program.start_date.to_date + (d - 1).day})}

  # given a program, returns a relation with all overlapping program(s) (including itself)
  # NOTE: initiation day for same program type are allowed to overlap (i.e allowing scope for combined initiation day for multiple programs)
  scope :all_overlapping, lambda { |program| Program.
      joins("JOIN program_donations ON programs.program_donation_id = program_donations.id").
      joins("JOIN program_types ON program_donations.program_type_id = program_types.id").
      joins("JOIN programs_date_timings ON programs.id = programs_date_timings.program_id").
      joins("JOIN date_timings ON programs_date_timings.date_timing_id = date_timings.id").
      where('programs_date_timings.date_timing_id IN (?) AND NOT (program_types.id = ? AND date_timings.date IN (?))',
      program.date_timing_ids,
      program.program_donation.program_type.id, program.program_donation.program_type.common_days.map{|d| program.start_date.to_date + (d - 1).day})}

  def initialize(*args)
    super(*args)
  end

  def dummy_init_time
    self.session_time = {:start=>['12:00 AM', '12:00 AM', '12:00 AM', '12:00 AM'],:end=>['12:00 AM', '12:00 AM', '12:00 AM', '12:00 AM']}
    self.intro_time = {:start=>['12:00 AM', '12:00 AM', '12:00 AM', '12:00 AM'],:end=>['12:00 AM', '12:00 AM', '12:00 AM', '12:00 AM']}
  end

  after_create do |program|
    program.reload
    program.update_attribute(:pid, "P#{1000+program.id}")
  end

  state_machine :state, :initial => STATE_UNKNOWN do

    event EVENT_PROPOSE do
      transition STATE_UNKNOWN => STATE_PROPOSED, :if => lambda {|t| t.can_create? }
    end
    before_transition STATE_UNKNOWN => STATE_PROPOSED, :do => :can_propose?
    after_transition STATE_UNKNOWN => STATE_PROPOSED, :do => :fill_proposer_id!

    event EVENT_ANNOUNCE do
      transition STATE_PROPOSED => STATE_ANNOUNCED, :if => lambda {|t| t.can_announce? }
    end
    before_transition any => STATE_ANNOUNCED, :do => :before_announce
    after_transition any => STATE_ANNOUNCED, :do => :on_announce

    event EVENT_DROP do
      transition STATE_PROPOSED => STATE_DROPPED, :if => lambda {|p| (p.current_user.is? :center_scheduler, :center_id => p.center_id) && !p.can_announce? }
    end
    before_transition any => STATE_DROPPED, :do => :can_drop?
    after_transition any => STATE_DROPPED, :do => :on_drop

    event EVENT_START do
      transition [STATE_ANNOUNCED, STATE_REGISTRATION_CLOSED] => STATE_IN_PROGRESS
    end
    after_transition any => STATE_IN_PROGRESS, :do => :on_start

    event EVENT_EXPIRE do
      transition STATE_PROPOSED => STATE_EXPIRED
    end
    after_transition any => STATE_EXPIRED, :do => :on_expire

    event EVENT_FINISH do
      transition STATE_IN_PROGRESS => STATE_CONDUCTED
    end
    after_transition any => STATE_CONDUCTED, :do => :on_finish

    event EVENT_CLOSE_REGISTRATION do
      transition STATE_ANNOUNCED => STATE_REGISTRATION_CLOSED, :if => lambda {|p| p.current_user.is? :center_scheduler, :center_id => p.center_id}
    end
    before_transition any => STATE_REGISTRATION_CLOSED, :do => :can_close_registration?
    after_transition any => STATE_REGISTRATION_CLOSED, :do => :close_registration

    event EVENT_REGISTRATION_CLOSE_TIMEOUT do
      transition STATE_ANNOUNCED => STATE_REGISTRATION_CLOSED
    end
    after_transition any => STATE_REGISTRATION_CLOSED, :do => :close_registration

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

    event EVENT_CANCEL do
      transition [STATE_ANNOUNCED, STATE_REGISTRATION_CLOSED] => STATE_CANCELLED, :if => lambda {|p| p.current_user.is? :zao, :center_id => p.center_id }
    end
    before_transition any => STATE_CANCELLED, :do => :can_cancel?
    after_transition any => STATE_CANCELLED, :do => :on_cancel

    # check for comments, before any transition
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

    # send notifications, after any transition
    after_transition any => any do |object, transition|
      object.store_last_update!(object.current_user, transition.from, transition.to, transition.event)
      object.notify(transition.from, transition.to, transition.event, object.center, object.teachers_connected_or_conducted_class)
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
    if [STATE_ANNOUNCED].include?(self.state)
      self.send(EVENT_START)
      self.save if self.errors.empty?
    end
    if [STATE_PROPOSED].include?(self.state)
      self.send(EVENT_EXPIRE)
      self.save if self.errors.empty?
    end
  end

  def trigger_registration_close
    return if !self.reloaded?
    if [STATE_ANNOUNCED].include?(self.state)
      self.send(EVENT_REGISTRATION_CLOSE_TIMEOUT)
      self.save if self.errors.empty?
    elsif [STATE_IN_PROGRESS].include?(self.state)
      self.close_registration
      self.save if self.errors.empty?
      # We need to manually send the notifications here, to avoid sending unnecessary notifications
      object.store_last_update!(User.current_user, STATE_IN_PROGRESS, STATE_REGISTRATION_CLOSED, EVENT_REGISTRATION_CLOSE_TIMEOUT)
      object.notify(STATE_IN_PROGRESS, STATE_REGISTRATION_CLOSED, EVENT_REGISTRATION_CLOSE_TIMEOUT, self.center, self.teachers_connected_or_conducted_class)
    end
  end

  def trigger_program_finish
    return if !self.reloaded?
    if [STATE_IN_PROGRESS].include?(self.state)
      self.send(EVENT_FINISH)
      self.save if self.errors.empty?
    elsif [STATE_EXPIRED].include?(self.state)
      # Expire other attached resources
      self.notify_all(FINISHED)
    end
  end

  def can_announce?
    if ready_for_announcement?
      return true if User.current_user.is? :center_scheduler, :center_id => self.center_id
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    else
      self.errors[:base] << "Program cannot be announced yet."
      return false
    end
  end

  def kit_capacity
    self.kit_schedules.joins('JOIN kits ON kits.id = kit_schedules.kit_id').where('kit_schedules.state = ?', ::KitSchedule::STATE_BLOCKED).pluck('kits.capacity').map{|v| v.to_i}.sum
  end

  def venue_capacity
    self.venue_schedules.joins('JOIN venues ON venues.id = venue_schedules.venue_id').where('venue_schedules.state = ?', ::VenueSchedule::STATE_PAID).pluck('venues.capacity').map{|v| v.to_i}.max
  end


  def new_timings_valid?(timings, new_time, type_of_timing)
    # make an array for the timing slots which were booked, each slot corresponds to 1 minute -
    # make an array for the timing slots being announced, each slot corresponds to 1 minute -
    blocked_slots = []
    announced_slots = []
    for i in 1..(24*60)
      blocked_slots[i-1] = false
      announced_slots[i-1] = false
    end
    # setting start_of_day to "2000-01-01 00:00" with appropriate time_zone
    start_of_day = Time.zone.parse("2000-01-01 00:00")

    # check if the gap between two timing is same as session duration, except when both are 12:00 AM
    duration_in_hrs = self.program_donation.program_type.session_duration
    for i in 1..timings.count
      blocked_start_time = timings[i-1].start_time
      blocked_end_time = timings[i-1].end_time
      # fill the slots that we have blocked
      start_in_mins = (blocked_start_time.hour - start_of_day.hour) * 60 + (blocked_start_time.min - start_of_day.min)
      end_in_mins = (blocked_end_time.hour - start_of_day.hour) * 60 + (blocked_end_time.min - start_of_day.min)
      # get teacher_ids blocked for given program, for given timing
      teacher_ids = self.teachers_connected_for_timing(timings[i-1].id)
      for j in start_in_mins..end_in_mins
        blocked_slots[j-1] = teacher_ids
      end

      # check for basic overlap
      start_time = new_time[:start][i-1]
      end_time = new_time[:end][i-1]
      if start_time > end_time
        self.errors[:base] << "Invalid values for #{type_of_timing} #{self.timing_name(timings[i-1])} slot. End time cannot be less than the Start time."
        return false
      end

      difference_in_minutes = ((end_time - start_time) / 1.minute).round
      if  difference_in_minutes != duration_in_hrs * 60
        # The user can blank out a time slot by making both start_time and end_time as 00:00 hrs
        # "2000-01-01 00:00" is equivalent to user enter 12:00 AM in the input value
        next if difference_in_minutes == 0 && start_time == start_of_day
        self.errors[:base] << "Invalid values for #{type_of_timing} #{self.timing_name(timings[i-1])} slot. Difference between Start and End time should be #{duration_in_hrs.to_s} hours."
        return false
      end

      # fill the slots that we are announcing, check if the slots overlap each other
      start_in_mins = (start_time.hour - start_of_day.hour) * 60 + (start_time.min - start_of_day.min)
      end_in_mins = (end_time.hour - start_of_day.hour) * 60 + (end_time.min - start_of_day.min)
      for j in start_in_mins..end_in_mins
        if announced_slots[j-1] != false
          self.errors[:base] << "Invalid value for #{type_of_timing} #{self.timing_name(timings[i-1])} slot. Start (or End) time overlaps with other slot."
          return false
        end
        announced_slots[j-1] = teacher_ids
      end
    end

    # check if the timings announced fall within the timing blocked earlier
    for i in 1..(24*60)
      if (announced_slots[i-1] != false) and (announced_slots[i-1] != blocked_slots[i-1])
        if (blocked_slots[i-1] == false)
          self.errors[:base] << "Invalid value for #{type_of_timing} Start (or End) time. Timings announced should fall within currently blocked timings."
        else
          self.errors[:base] << "Invalid value for #{type_of_timing} Start (or End) time. Timings announced cannot overlap the currently blocked timings, when scheduled teacher(s) are not same."
        end
        return false
      end
    end

    return true
  end

  def new_residential_timings_valid?(start_time, end_time)
    if start_time.utc.strftime("%H%M%S") < self.start_date.to_time.utc.strftime("%H%M%S")
      self.errors[:base] << "Invalid value for Start time. Start time cannot be less than #{self.start_date.strftime('%I:%M %P')}"
      return false
    end

    if end_time.utc.strftime("%H%M%S") > self.end_date.to_time.utc.strftime("%H%M%S")
      self.errors[:base] << "Invalid value for End time. End time cannot exceed #{self.end_date.strftime('%I:%M %P')}"
      return false
    end

    return true
  end

  def valid_contact_phone?
    return true if self.contact_phone.blank?
    phones = self.contact_phone.delete(' ').split(',')
    phones.each { |phone|
      # check if valid mobile number -- (ten digit numeric)
      valid_mobile = (phone.length == 10 and phone.to_i.to_s == phone)
      # else check if valid stdcode-number -- (0[0-9]{2,4}-[0-9]{6,8})
      next if valid_mobile
      p = phone.split('-')
      valid_landline = (p.count == 2 and p[0][0] == '0' and p[0].length.between?(2,4) and p[1].length.between?(6,8))
      return false if not valid_landline
    }
    return true
  end


  def valid_contact_email?
    return true if self.contact_email.blank?
    email_ids = self.contact_email.delete(' ').split(',')
    email_ids.each {|email_id|
      return false if not ValidateEmail.valid?(email_id)
    }
    return true
  end

  def before_announce
    if self.capacity.nil? || self.capacity <= 0
      self.errors[:capacity] << " should be non-zero."
      return false
    end
    if self.announced_locality.nil? || self.announced_locality.blank?
      self.announced_locality = self.center.name
    end

    if not self.valid_contact_phone?
      self.errors[:contact_phone] << " invalid. Please enter valid phone number(s)."
      return false
    end

    if not self.valid_contact_email?
      self.errors[:contact_email] << " invalid. Please enter valid email id(s)."
      return false
    end

    new_start_time = ""
    new_end_time = ""
    #
    # If residential, e.g., BSP
    #
    # announced_timing = "Arrive by: 4pm on 17th\nProgram ends: 6:30pm on 20th"
    # timing_str = "Starts on 2nd at 5:00pm. Ends on 6th by 1:00pm"
    #
    if self.residential?
      new_start_time = start_time = self.session_time[:start][0]
      new_end_time = end_time = self.session_time[:end][0]
      return false unless self.new_residential_timings_valid?(new_start_time, new_end_time)
      self.announced_timing = "Arrive by: #{start_time.strftime("%-I:%M%P")} on #{self.start_date.day.ordinalize}.\nProgram ends: #{end_time.strftime("%-I:%M%P")} on #{self.end_date.day.ordinalize}"
      self.timing_str = "Starts on #{self.start_date.day.ordinalize} at #{start_time.strftime("%-I:%M%P")}. Ends on #{self.end_date.day.ordinalize} by #{end_time.strftime("%-I:%M%P")}."
    else
      #
      # If non-residential, e.g., IE, or Uyir Nokkam
      #
      return false unless self.new_timings_valid?(self.timings, self.session_time, "session")
      # fill the session timings
      session_announced_timing = ""
      session_timing_str = ""
      count = 0
      for i in 1..self.timings.count
        # timing_name = self.timing_name(i-1)
        start_time = self.session_time[:start][i-1]
        end_time = self.session_time[:end][i-1]
        # include only the valid slots
        new_timing_str = ""
        if ((end_time - start_time) / 1.minute).round > 0
          count = count + 1
          #new_timing_str = "#{timing_name} (#{start_time.strftime("%-I:%M%P")} - #{end_time.strftime("%-I:%M%P")}) OR "
          new_timing_str = "#{start_time.strftime("%-I:%M%P")} - #{end_time.strftime("%-I:%M%P")}"
          session_announced_timing << "#{new_timing_str} OR "
          session_timing_str << "#{new_timing_str}, "
          new_start_time = start_time if new_start_time.blank?
          new_end_time = end_time
        end
        # TODO - fix this
        # update linked teacher schedule timing str
        self.update_teacher_schedule_timing_str(self.timings[i-1].id, new_timing_str)
      end

      #
      # If no intro, e.g., Uyir Nokkam
      #
      # announced_timing = "(4 batches): 9:30am - 10:30am OR 9:30am - 10:30am OR 9:30am - 10:30am OR 9:30am - 10:30am"
      # timing_str = "9:30am - 10:30am, 9:30am - 10:30am, 9:30am - 10:30am, 9:30am - 10:30am"
      #
      if not self.has_intro?
        self.announced_timing = "(#{count} batches): " + session_announced_timing.chomp(" OR ")
        self.timing_str = session_timing_str.chomp(", ")
      else
        #
        # If intro, e.g., IE
        #
        # announced_timing =
        #   "(intro)\n"
        #   "Wed 7 Jan: 6:00am - 7:15am OR 6:00pm - 7:15pm\n"
        #   "(session)\n"
        #   "Wed 7 Jan: 7:30am - 9:00am OR 7:30pm - 9:00pm\n"
        #   "Thu-Tue (3 batches): 6:00am - 9:00am OR 10:00am - 1:00pm OR 6:00pm - 9:00pm\n"
        #   "Sun 11 Jan: Full day\n"
        #
        # timing_str =
        #   "(Intro) Morning (6am - 10am), Night(6pm - 10pm); (Session) Morning (6am - 10am), Afternoon (10am - 2pm), Night (6pm - 10pm)"
        #
        return false unless self.new_timings_valid?(self.intro_timings, self.intro_time, "intro")
        intro_announced_timing_1 = ""
        intro_announced_timing_2 = ""
        intro_timing_str = ""
        intro_duration = self.program_donation.program_type.intro_duration
        intro_day = self.program_donation.program_type.intro_day
        full_days = self.program_donation.program_type.full_days
        for i in 1..self.intro_timings.count
          start_time = self.intro_time[:start][i-1]
          end_time = self.intro_time[:end][i-1]
          # include only the valid slots
          if ((end_time - start_time) / 1.minute).round > 0
            intro_announced_timing_1 << "#{start_time.strftime("%-I:%M%P")} - #{(start_time + intro_duration.minutes).strftime("%-I:%M%P")} OR "
            intro_announced_timing_2 << "#{(start_time + intro_duration.minutes).strftime("%-I:%M%P")} - #{(end_time).strftime("%-I:%M%P")} OR "
            intro_timing_str << "#{start_time.strftime("%-I:%M%P")} - #{end_time.strftime("%-I:%M%P")}, "
            new_start_time = start_time if i == 1
          end
        end

        full_days_str = full_days.map{|d| "#{(self.start_date + (d-1).days).strftime('%a %-d %b')}"}.join(", ")
        self.announced_timing = "(intro)\n #{intro_announced_timing_1.chomp(' OR ')}"\
                             "\n(session)\n#{(self.start_date + (intro_day-1).days).strftime('%a %-d %b')}: #{intro_announced_timing_2.chomp(' OR ')}"\
                             "\n#{(self.start_date + (intro_day).days).strftime('%a')}-#{self.end_date.strftime('%a')} (#{count} batches): #{session_announced_timing.chomp(' OR ')}"\
                             "\n#{full_days_str}: Full Day\n"
                             #"\n#{(self.start_date + (full_day-1).days).strftime('%a %-d %b')}: Full Day\n"
        self.timing_str = "(Intro) #{intro_timing_str.chomp(', ')}; (Session) #{session_timing_str.chomp(', ')}"
        #self.announced_timing = "(intro)\n" + intro_announced_timing_1.chomp(" OR ")
        #                    + "\n(session)\n" + "#{(self.start_date + (intro_day-1).days).strftime("%a %-d %b")}:" + intro_announced_timing_2.chomp(" OR ")
        #                    + "\n#{(self.start_date + (intro_day).days).strftime("%a")}-#{self.end_date.strftime("%a")} (#{count} batches): " + session_announced_timing.chomp(" OR ")
        #                    + "\n#{(self.start_date + (full_day-1).days).strftime("%a %-d %b")}: Full Day\n"
        #self.timing_str = "(Intro) " + intro_timing_str.chomp(", ") + "; (Session) " + session_timing_str.chomp(", ")
      end
    end

    # update the start_date_time and end_date_time for the program
    self.start_date = self.start_date.change(:hour => new_start_time.hour, :min => new_start_time.min, :sec => new_start_time.sec)
    self.end_date = self.end_date.change(:hour => new_end_time.hour, :min => new_end_time.min, :sec => new_end_time.sec)

    #if self.announced_timing.nil? || self.announced_timing.blank?
    #  self.errors[:announced_timing] << " cannot be blank."
    #  return false
    #end

    return can_announce?
  end

  def locality_name
    if self.announced_locality.nil? ||  self.announced_locality.blank?
      self.center.name
    else
      "#{self.announced_locality} (#{self.center.name})"
    end
  end

  def residential?
    self.program_donation.program_type.residential?
  end

  def has_intro?
    self.program_donation.program_type.has_intro?
  end

  def timing_name(timing)
    "#{timing.name.sub /\s*\(.+\)$/, ''}"
  end

  def display_timings
    self.timing_str
    # if self.residential?
    #   timings_str = 'Full Day'
    # else
    #   timings_str = (self.timings.map {|c| c[:name]}).join(", ")
    # end
    # timings_str = self.announced_timing if self.is_announced?
    # timings_str
  end

  def intro_timings_subset?
    self.errors.add(:intro_timings, " cannot exceed Timings.") if not (self.intro_timings - self.timings).empty?
  end


  def on_announce
    self.announced = true
    self.update_attribute("announced",true)
    # Changed by Senthil, open the registration once it is announced. By default registration is closed. Registration is opened only in announced state.
    self.update_attribute("registration_closed", false)
    logger.info "Opening the registration for program id - #{self.id}"
    # generate_program_id!
    self.notify_all(ANNOUNCED)
    # start the timer for start of class notification
    self.delay(:run_at => self.start_date).trigger_program_start
    # start the timer for registration close
    self.delay(:run_at => (self.start_date + self.program_donation.program_type.registration_close_timeout.hours)).trigger_registration_close

  end

  def can_close_registration?
    return true if (User.current_user.is? :center_scheduler, :center_id => self.center_id)
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def close_registration
    logger.info "Closing the registration for program id - #{self.id}"
    self.registration_closed = true
    self.update_attribute("registration_closed", true)
    logger.info "Value of registration flag after closing. #{self.registration_closed}"
    logger.info "In case of error after closing registration #{self.errors.inspect}"
  end

  def can_drop?
    if (User.current_user.is? :sector_coordinator, :center_id => self.center_id)
      if self.venue_approved?
        self.errors[:base] << "Cannot drop program. Venue linked to the program has already gone for payment request."
        return false
      end
      return true
    end

    if (User.current_user.is? :center_scheduler, :center_id => self.center_id)
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
    self.notify_all(DROPPED)
  end

  def on_start
    self.notify_all(STARTED)
    # start the timer for close of class notification
    self.delay(:run_at => self.end_date).trigger_program_finish
  end

  def on_expire
    # We won't notify expiry here, we will wait till the end of the class
    # Other alternative is
    # 1. to inform of expiry to resources and free the relevant resources?
    # 2. to send notification to all the attached resources and their owners
    # We are doing neither here, since on expiry we are notifying the relevant schedulers.
    # They are expected to manually free the resources which are blocked for the program.
    #self.notify_all(EXPIRED)

    # start the timer for close of class notification, this is needed to expire other resource, if they are still attached
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
    return true if User.current_user.is? :zao, :center_id => self.center_id
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end


  def can_close?
    if ready_for_close?
      return true if User.current_user.is? :center_coordinator, :center_id => self.center_id
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    else
      self.errors[:base] << "Program cannot be closed yet."
      return false
    end
  end

  def can_cancel?
    return true if (User.current_user.is? :zao, :center_id => self.center_id)
    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    return false
  end

  def on_cancel
    self.notify_all(CANCELLED)
  end

  def friendly_name
    ("#%s %s (%s, %s, %s)" % [self.pid, self.name, self.start_date.strftime('%d %B %Y'), self.center.name, self.program_donation.program_type.name])
  end


  def url
    Rails.application.routes.url_helpers.program_url(self)
  end

  def friendly_first_name_for_email
    "Program #{self.pid}"
   end

  def friendly_second_name_for_email
    "  #{self.name} (#{self.center.name} #{self.program_donation.program_type.name}) #{self.start_date.strftime('%d %B')}-#{self.end_date.strftime('%d %B %Y')}"
  end

  def friendly_name_for_sms
    "Program #{self.pid} #{self.name}"
  end


  def is_announced?
    self.announced == true
  end

  def in_progress?
    self.state == STATE_IN_PROGRESS
  end

=begin
  def generate_program_id!
    self.announce_program_id = ("%s %s %d" % 
      [self.center.name, self.start_date.strftime('%B%Y'), self.id]
    ).parameterize
    #self.save!
  end
=end
  
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
      ts.current_user = User.current_user
      ts.on_program_event(event)
    }
    self.venue_schedules.each{|vs|
      vs.current_user = User.current_user
      vs.on_program_event(event)
    }
    self.kit_schedules.each{|ks|
      ks.current_user = User.current_user
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
    venues = Venue.joins("JOIN centers_venues ON venues.id = centers_venues.venue_id").where('centers_venues.center_id = ? AND venues.state = ? ', self.center_id, ::Venue::STATE_POSSIBLE).order('LOWER(venues.name) ASC').all
    blockable_venues = []
    venues.each {|venue|
      blockable_venues << venue if venue.can_be_blocked_by?(self)
    }
    blockable_venues
  end


  def blockable_kits
    kits = Kit.joins("JOIN centers_kits ON kits.id = centers_kits.kit_id").where('centers_kits.center_id = ?', self.center_id).all
    blockable_kits = []
    kits.each {|kit|
      blockable_kits << kit if kit.can_be_blocked_by?(self)
    }
    blockable_kits
  end

  def assign_dates!
    if !self.start_date.nil? && !self.program_donation.program_type.nil?
      self.end_date = self.start_date + (self.no_of_days.days - 1.day)
    end
    #@program.update_attributes :start_date => @program.start_date_time, :end_date => @program.end_date_time
  end

  def no_of_days
    self.program_donation.program_type.no_of_days.to_i
  end

  #def no_of_teachers_connected_or_conducted_class(role=nil)
  #  return 0 if self.teacher_schedules.blank?
  #  if role.blank?
  #    no_of_teachers = {}
  #    self.role.each { |r|
  #      no_of_teachers[r] =  self.teacher_schedules.where('state IN (?) AND role = ? ', (::ProgramTeacherSchedule::CONNECTED_STATES + [::ProgramTeacherSchedule::STATE_COMPLETED_CLASS]), r).group('teacher_id').length
  #    }
  #    return no_of_teachers
  #  else
  #   return self.teacher_schedules.where('state IN (?) AND role = ? ', (::ProgramTeacherSchedule::CONNECTED_STATES + [::ProgramTeacherSchedule::STATE_COMPLETED_CLASS]), role).group('teacher_id').length
  #  end
  #end

  def no_of_teachers_connected(role, timing)
    return 0 if self.teacher_schedules.blank?
    self.teacher_schedules.where('state IN (?) AND role = ? AND timing_id = ?', ::ProgramTeacherSchedule::CONNECTED_STATES, role, timing.id).group('teacher_id').length
  end

  def teachers_connected(role)
    return [] if self.teacher_schedules.blank?
    self.teacher_schedules.where('state IN (?) AND role = ?', ::ProgramTeacherSchedule::CONNECTED_STATES, role).group('teacher_id')
  end

  def teachers_connected_for_timing(timing_id)
    return [] if self.teacher_schedules.blank?
    teacher_ids = self.teacher_schedules.where('state IN (?) AND timing_id = ?', ::ProgramTeacherSchedule::CONNECTED_STATES, timing_id).pluck('teacher_id')
    teacher_ids.uniq.sort
  end

  def teachers_conducted_class(role)
    return [] if self.teacher_schedules.blank?
    self.teacher_schedules.where('state IN (?) AND role = ?', [::ProgramTeacherSchedule::STATE_COMPLETED_CLASS], role).group('teacher_id')
  end

  def teachers_connected_or_conducted_class
    return [] if self.teacher_schedules.blank?
    teachers = []
    self.roles.each { |role|
      teachers << self.teacher_schedules.where('state IN (?) AND role = ?', ::ProgramTeacherSchedule::CONNECTED_STATES + [::ProgramTeacherSchedule::STATE_COMPLETED_CLASS], role).group('teacher_id')
    }
    teachers.uniq
  end

  def minimum_no_of_teacher(role)
    self.program_donation.program_type.role_minimum_no_of_teacher(role)
  end

  def update_teacher_schedule_timing_str(timing_id, timing_str)
    self.teacher_schedules.where('state IN (?) AND timing_id = ?', ::ProgramTeacherSchedule::CONNECTED_STATES, timing_id).update_all(:timing_str => timing_str)
  end

  def roles
    self.program_donation.program_type.roles
  end

  def minimum_teachers_connected?(plus=0)
    self.roles.each { |role|
      self.timings.each { |timing|
        if self.no_of_teachers_connected(role, timing) < (self.minimum_no_of_teacher(role) + plus)
          return false
        end
      }
    }
    return true
  end

  def program_needs_co_teacher?
    self.program_donation.program_type.minimum_no_of_co_teacher > -1
  end

  def is_teacher?
    # super_admin can perform actions on behalf of the teacher
    return true if User.current_user.is? :super_admin
    self.teacher_schedules.each { |ts|
      if ((::ProgramTeacherSchedule::CONNECTED_STATES + [::ProgramTeacherSchedule::STATE_COMPLETED_CLASS]).include?(ts.state) && ts.teacher.user == User.current_user)
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
    timing = Timing.joins("JOIN date_timings ON timings.id = date_timings.timing_id").joins("JOIN programs_date_timings ON date_timings.id = programs_date_timings.date_timing_id").where('programs_date_timings.program_id = ?', self.id).order('date_timings.date ASC, start_time ASC').first
    self.start_date.advance(:hours => timing.start_time.hour, :minutes => timing.start_time.min, :seconds => timing.start_time.sec)
  end

  def end_date_time
    timing = Timing.joins("JOIN date_timings ON timings.id = date_timings.timing_id").joins("JOIN programs_date_timings ON date_timings.id = programs_date_timings.date_timing_id").where('programs_date_timings.program_id = ?', self.id).order('date_timings.date DESC, end_time DESC').first
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
    if (self.no_of_venues_connected > 0)
      self.errors[:base] << "Cannot close program, linked venue is not closed. Please close it and try again."
      return false
    end

    if (self.no_of_kits_connected > 0)
      self.errors[:base] << "Cannot close program, linked kit is not closed. Please close it and try again."
      return false
    end

    self.roles.each { |role|
      self.timings.each { |timing|
        if self.no_of_teachers_connected(role, timing) > 0
          self.errors[:base] << "Cannot close program, Teacher(s) are still linked to the program."
          return false
        end
      }
    }

    return true
  end

  def ready_for_announcement?
    return false unless self.no_of_venues_paid > 0
    return false unless self.no_of_kits_connected > 0
    return false unless self.minimum_teachers_connected?
    return true
  end


  def can_view?
    return true if User.current_user.is? :any, :in_group => [:geography], :center_id => self.center_id
    return true if User.current_user.is? :any, :in_group => [:pcc], :center_id => self.center_id
    return false
  end

  def can_propose?
    return self.can_create?
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

    return true if User.current_user.is? :center_scheduler, :center_id => center_ids
    return false
  end

  def can_update?
    return true if User.current_user.is? :center_scheduler, :center_id => self.center_id
    return false
  end

  def teacher_status
    errors = []
    self.roles.each { |role|
      self.timings.each { |timing|
        connected = self.no_of_teachers_connected(role, timing)
        minimum = self.minimum_no_of_teacher(role)
        session = timing.name
        errors << "<i>#{role}(s)</i> added = <b>#{connected}</b> for <i>#{session}</i>. Please add <b>#{minimum-connected}</b> more." if connected < minimum
      }
    }
    if errors.empty?
      return ['<span class="label label-success">Ready</span>']
    else
      return errors
    end
  end

  def venue_status
    return ["Please Add a Venue (Venue should be in Proposed state)"] if self.no_of_venues_connected == 0
    return ['<span class="label label-success">Ready</span>'] if self.no_of_venues_paid > 0
    status = []
    self.venue_schedules.each { |vs|
      next unless vs.is_connected?
      case vs.state
        when ::VenueSchedule::STATE_BLOCK_REQUESTED
          status << "(#{vs.venue.name} Block Requested) Please ask Venue Coordinator to approve the request."
        when ::VenueSchedule::STATE_BLOCKED
          status << "(#{vs.venue.name} Blocked) Please send Approval Request to Sector Coordinator once Kit and Teacher are Ready."
        when ::VenueSchedule::STATE_APPROVAL_REQUESTED
          status << "(#{vs.venue.name} Approval Requested) Please ask Sector Coordinator to approve the request."
        when ::VenueSchedule::STATE_PAYMENT_PENDING
          status << "(#{vs.venue.name} Payment Pending) Please ask PCC Accounts to approve the request."
        else
          status << "#{vs.venue.name} => #{vs.state}"
      end
    }
    status
  end

  def kit_status
    return ["Please Add a Kit"] if self.no_of_kits_connected == 0
    return ['<span class="label label-success">Ready</span>'] if self.no_of_kits_connected > 0
  end
end
