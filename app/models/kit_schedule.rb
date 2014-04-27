# == Schema Information
#
# Table name: kit_schedules
#
#  id                   :integer          not null, primary key
#  start_date           :date
#  end_date             :date
#  state                :string(255)
#  issued_to_person_id  :integer
#  blocked_by_person_id :integer
#  program_id           :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  comments             :string(255)
#  kit_id               :integer
#

class KitSchedule < ActiveRecord::Base
  include CommonFunctions

  before_destroy :can_delete?

  STATE_RESERVED    = "Reserved"
  STATE_UNDER_REPAIR = "Under Repair"
  STATE_UNAVAILABLE_OVERDUE = "Kit Overdue"

  STATE_BLOCKED     = "Blocked"
  STATE_ISSUED      = "Issued"
  STATE_ASSIGNED    = "Assigned"
  STATE_OVERDUE     = "Overdue"
  STATE_RETURNED    = "Returned"
  STATE_CANCELLED   = "Cancelled"
  STATE_CLOSED      = "Closed"

  FINAL_STATES = [STATE_CLOSED, STATE_CANCELLED]
  CONNECTED_STATES = [STATE_BLOCKED, STATE_ASSIGNED, STATE_ISSUED, STATE_OVERDUE, STATE_RETURNED]
  RESERVED_STATES = [STATE_RESERVED, STATE_UNDER_REPAIR, STATE_UNAVAILABLE_OVERDUE]
  ALL_STATES = RESERVED_STATES + FINAL_STATES + CONNECTED_STATES

  EVENT_RESERVE    = "Reserve Kit"
  EVENT_UNDER_REPAIR = "Kit Under Repair"
  EVENT_UNAVAILABLE_OVERDUE = "Kit Overdue"

  EVENT_BLOCK      = "Block"
  EVENT_ISSUE      = "Issue"
  EVENT_OVERDUE    = "Overdue"
  EVENT_CANCEL     = "Cancel"
  EVENT_RETURNED   = "Returned"
  EVENT_CLOSE      = "Close"

  NOTIFICATIONS = [EVENT_OVERDUE]
  NON_MENU_EVENTS = [EVENT_BLOCK, EVENT_RESERVE, EVENT_UNDER_REPAIR, EVENT_UNAVAILABLE_OVERDUE]
  PROCESSABLE_EVENTS = [EVENT_ISSUE, EVENT_RETURNED, EVENT_CANCEL, EVENT_CLOSE]

  EVENTS_WITH_COMMENTS = [EVENT_UNDER_REPAIR, EVENT_UNAVAILABLE_OVERDUE, EVENT_RESERVE, EVENT_CANCEL, EVENT_RETURNED, EVENT_ISSUE]
  EVENTS_WITH_FEEDBACK = [EVENT_CLOSE]

  belongs_to :kit
  belongs_to :program
  belongs_to :blocked_by_user, :class_name => User
  belongs_to :last_updated_by_user, :class_name => User
  attr_accessible :last_update, :last_updated_at

  attr_accessor :comment_category
  attr_accessible :comment_category

  attr_accessor :current_user, :issue_for_schedules
  attr_accessible :program_id, :kit_id,:end_date, :start_date, :state, :comments, :issued_to, :due_date_time, :issue_for_schedules

  validates :start_date, :presence => true
  validates :end_date, :presence => true
  validates :kit_id , :presence => true
  validates :state , :presence => true
  validates :program_id, :presence => true, :unless => :kit_reserved?
  validates_uniqueness_of :program_id, :scope => "kit_id", :unless => :kit_reserved_or_cancelled?, :message => " is already associated with the Kit."

  #checking for overlap validation
  validates_with KitScheduleValidator

=begin
  # given a kit_schedule (linked to a program), returns a relation with other overlapping kit_schedule(s) (linked to programs) for the specific kit, not in specified states
  scope :overlapping_blocks, lambda { |ks, states| joins(:program).merge(Program.overlapping(ks.program)).where('kit_schedules.id IS NOT ? AND kit_schedules.state NOT IN (?) AND kit_schedules.kit_id IS ?', ks.id, states, ks.kit_id) }

  # given a kit_schedule (not linked to program), returns a relation with other overlapping kit_schedule(s) (linked to programs) for the specific kit, not in specified states
  scope :overlapping_date_time_blocks, lambda { |ks, states| joins(:program).merge(Program.overlapping_date_time(ks.start_date, ks.end_date)).where('kit_schedules.id IS NOT ? AND kit_schedules.state NOT IN (?) AND kit_schedules.kit_id IS ?', ks.id, states, ks.kit_id) }

  # given a kit_schedule, returns a relation with other overlapping kit_schedule(s) (not linked to program), for the specific kit, in specified states
  scope :overlapping_reserves, lambda { |ks| where('kit_schedules.program_id IS NULL AND kit_schedules.id IS NOT ? AND kit_schedules.state IN (?) AND kit_schedules.kit_id IS ? AND ((kit_schedules.start_date BETWEEN ? AND ?) OR (kit_schedules.end_date BETWEEN ? AND ?) OR  (kit_schedules.start_date <= ? AND kit_schedules.end_date >= ?))',
                                                       ks.id, RESERVED_STATES, ks.kit_id, ks.start_date, ks.end_date, ks.start_date, ks.end_date, ks.start_date, ks.end_date)}

  # given end date of a kit_schedule, returns a relation with  kit_schedule(s) where it falls in middle of start and end date, for the specific kit, not in specified states
  scope :end_date_in_middle, lambda { |ks| where('kit_schedules.program_id IS NOT NULL AND kit_schedules.id IS NOT ? AND kit_schedules.state IN (?)  AND kit_schedules.kit_id IS ? AND (? BETWEEN kit_schedules.start_date AND kit_schedules.end_date)',
                                                         ks.id, [STATE_ASSIGNED], ks.kit_id, ks.end_date)}
=end

  # given a kit_schedule, returns a relation with other overlapping kit_schedule(s), for the specific kit, in specified states
  scope :overlapping_schedules, lambda { |ks| where('kit_schedules.id IS NOT ? AND kit_schedules.state NOT IN (?) AND kit_schedules.kit_id IS ? AND ((kit_schedules.start_date BETWEEN ? AND ?) OR (kit_schedules.end_date BETWEEN ? AND ?) OR  (kit_schedules.start_date <= ? AND kit_schedules.end_date >= ?))',
                                                   ks.id, FINAL_STATES, ks.kit_id, ks.start_date, ks.end_date, ks.start_date, ks.end_date, ks.start_date, ks.end_date)}


  def initialize(*args)
    super(*args)
  end
   
  state_machine :state , :initial => ::Kit::STATE_AVAILABLE do

    event EVENT_BLOCK do
      transition [::Kit::STATE_AVAILABLE] => STATE_BLOCKED, :if => lambda {|t| t.can_create?}
    end
    before_transition any => STATE_BLOCKED, :do => :before_block
    after_transition any => STATE_BLOCKED, :do => :on_block

    event ::Program::ANNOUNCED do
      transition STATE_BLOCKED => STATE_ASSIGNED
    end

    event EVENT_ISSUE do
      transition [STATE_ASSIGNED] => STATE_ISSUED, :if => lambda {|t| t.is_kit_coordinator? }
    end
    before_transition any => STATE_ISSUED, :do => :before_issue
    after_transition any => STATE_ISSUED, :do => :after_issue

    event EVENT_RETURNED do
      transition [STATE_OVERDUE, STATE_ISSUED] => STATE_RETURNED, :if => lambda {|t| t.is_kit_coordinator? }
    end
    before_transition any => STATE_RETURNED, :do => :is_kit_coordinator?

    event EVENT_CLOSE do
      transition STATE_RETURNED => STATE_CLOSED, :if => lambda {|t| t.is_center_coordinator? }
    end
    before_transition STATE_RETURNED => STATE_CLOSED, :do => :is_center_coordinator?

    event EVENT_OVERDUE do
      #transition [STATE_BLOCKED, STATE_ISSUED, STATE_ASSIGNED] => STATE_OVERDUE
      transition [STATE_ISSUED] => STATE_OVERDUE
    end

    event EVENT_CANCEL do
      transition STATE_BLOCKED => STATE_CANCELLED, :if => lambda {|t| t.current_user.is? :center_scheduler, :center_id => t.program.center_id }
    end
    before_transition STATE_BLOCKED => STATE_CANCELLED, :do => :can_unblock?

    event ::Program::DROPPED do
      transition STATE_BLOCKED => STATE_CANCELLED
    end

    event ::Program::CANCELLED do
      transition STATE_ASSIGNED => STATE_CANCELLED
    end

    event EVENT_RESERVE do
      transition ::Kit::STATE_AVAILABLE => STATE_RESERVED, :if => lambda {|t| t.can_create_reserve? }
    end
    before_transition any => STATE_RESERVED, :do => :can_create_reserve?

    event EVENT_UNDER_REPAIR do
      transition ::Kit::STATE_AVAILABLE => STATE_UNDER_REPAIR, :if => lambda {|t| t.can_create_overdue_or_under_repair? }
    end

    event EVENT_UNAVAILABLE_OVERDUE do
      transition ::Kit::STATE_AVAILABLE => STATE_UNAVAILABLE_OVERDUE, :if => lambda {|t| t.can_create_overdue_or_under_repair? }
    end
    before_transition any => [STATE_UNDER_REPAIR, STATE_UNAVAILABLE_OVERDUE], :do => :can_create_overdue_or_under_repair?
    after_transition ::Kit::STATE_AVAILABLE => [STATE_RESERVED, STATE_UNDER_REPAIR, STATE_UNAVAILABLE_OVERDUE], :do => :after_reserve!

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
      object.notify(transition.from, transition.to, transition.event, object.program.center_id)
    end
  end


  def before_block
    return false unless self.can_create?
    self.start_date = self.program.start_date.to_date - 1.day
    self.end_date = (self.program.end_date.to_date + 2.day - 1.minute).to_date
#    self.start_date = self.program.start_date
#    self.end_date = self.program.end_date
  end

  def on_block
    self.blocked_by_user = current_user
    self.issue_for_schedules = NIL
    self.send(::Program::ANNOUNCED) if self.program.is_announced? && self.program.is_active?
  end

  def kit_reserved?
    RESERVED_STATES.include?(self.state)
  end

  def kit_reserved_or_cancelled?
    return true if kit_reserved?
    KitSchedule.where('program_id IS ? AND kit_id IS ? AND state NOT IN (?)', self.program_id, self.kit_id, FINAL_STATES).count == 0
  end

  def is_kit_coordinator?
    unless self.current_user.is? :kit_coordinator, :center_id => self.program.center_id
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    end
    true
  end

  def is_center_coordinator?
    unless self.current_user.is? :center_coordinator, :center_id => self.program.center_id
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    end
    true
  end

  def before_issue
    return false unless self.is_kit_coordinator?

    #return false unless self.has_comments?
    if self.issued_to.nil?
      self.errors[:issued_to] << " cannot be blank."
      return false
    end
    self.due_date_time = self.end_date
    true
  end

=begin
  def before_issue
    return false unless self.comments_present?
    unless self.issue_for_schedules.nil?
      self.issue_for_schedules.each { |ks_id|
        ks = KitSchedule.find(ks_id.to_i)
        # something might have changed - not flagging any error
        if ks && ks.state == STATE_ASSIGNED
          ks.issue_for_schedules = []
          ks.due_date_time = self.due_date_time
          ks.comments = self.comments
          ks.issued_to = self.issued_to
          ks.send(EVENT_ISSUE)
          # TODO - check if we need to do any error handling error
        end
      }
      return true
    end

    if self.issued_to.nil?
      self.errors[:issued_to] << " cannot be blank."
      return false
    end

    if self.due_date_time.nil? || self.due_date_time < Time.zone.now
      self.errors[:due_date_time] << " should be valid."
      return false
    end

    if self.due_date_time < self.end_date
      self.errors[:due_date_time] << " cannot be before end date of the program."
      return false
    end

    # TODO - check if the due_date and time overlaps with any of the schedule

    if self.due_date_time
      # save the dates
      saved_start_time = self.start_date
      saved_end_date = self.end_date

      # hack to reuse the time checks
      self.start_date = Time.zone.now
      self.end_date = self.due_date_time

      # 1. check overlap for other reserves, or kit schedules where kit not assigned - FAIL
      if KitSchedule.overlapping_reserves(self).count() > 0
        self.errors[:base] << "Due Date overlaps with other schedules. Please change due date and try again."
        return false
      end

      states = FINAL_STATES + [STATE_ASSIGNED]
      if KitSchedule.overlapping_date_time_blocks(self, states).count() > 0
        self.errors[:base] << "Due Date overlaps with other schedule where kit has not been assigned. Please change due date, or update kit schedule status to assigned, and try again"
        return false
      end

      # 2. check overlap for assigned kit schedules with due date in middle of program - FAIL
      states = FINAL_STATES
      if KitSchedule.end_date_in_middle(self).count() > 0
        self.errors[:base] << "Due Date is in middle of other schedule where kit has been assigned. Please change due date and try again."
        return false
      end

      # get a list of overlapping schedules
      states = ALL_STATES - [STATE_ASSIGNED]
      additional_kit_schedules = KitSchedule.overlapping_date_time_blocks(self, states).all
      #comments = @males.map {|user| user.comments.map(&:content)}.flatten

      # 3. check overlap for assigned kit schedules with center(s) for which not KC - FAIL, with whom to approach
      additional_kit_schedules.each {|ks|
        unless self.current_user.is? :kit_coordinator, :center_id => ks.program.center_id
          record.errors[:base] << "Insufficient privileges to complete operation. Due Date overlaps with schedule for the kit assigned to other center. Either change due date and try again, or contact Sector/ Zonal coordinator."
          return false
        end
      }
      # restore the dates
      self.start_date = saved_start_time
      self.end_date = saved_end_date

      # for other overlap - confirm once - start delay_job on last program, pass kit_schedule list as parameter to delay_job
      if additional_kit_schedules
        self.issue_for_schedules = additional_kit_schedules.collect(&:id)
        self.errors[:base] << "Due Date overlaps with other schedules where kit is assigned. Do you want to issue the kit for all the schedules?"
        return false
      end
    end

    true
  end
=end

  def reloaded?
    self.reload
    return true
  rescue ActiveRecord::RecordNotFound
    # TODO - check if to log any error
    return false
  end

  def trigger_overdue
    return if !self.reloaded?
    #if [STATE_BLOCKED, STATE_ISSUED, STATE_ASSIGNED].include?(ks.state)
    if ks.state == STATE_ISSUED
      self.send(EVENT_OVERDUE)
      self.save if self.errors.empty?
    end
  end

  def after_issue
    self.delay(:run_at => self.due_date_time).trigger_overdue
    self.issue_for_schedules = NIL
    true
  end

  def can_unblock?
    # to prevent too many error messages on console return early
    if (self.current_user.is? :sector_coordinator, :center_id => self.program.center_id)
      if self.program.venue_approved?
        self.errors[:base] << "Cannot cancel kit block. Venue linked to the program has already gone for payment request."
        return false
      end
      return true
    end

    if (self.current_user.is? :center_scheduler, :center_id => self.program.center_id)
      if self.program.venue_approval_requested?
        self.errors[:base] << "Cannot cancel kit block. Venue linked to the program has already gone for sector coordinator approval."
        return false
      end
      return true
    end

    self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
    false
  end

  def after_reserve!
    self.blocked_by_user = self.current_user
  end

  def is_connected?
    self.program_id && CONNECTED_STATES.include?(self.state)
  end


  def on_program_event(event)
    valid_states = {
        ::Program::CANCELLED => [STATE_ASSIGNED],
        ::Program::DROPPED => [STATE_BLOCKED],
        ::Program::ANNOUNCED => [STATE_BLOCKED],
    }
    # verify when all the events can come
    if valid_states[event].include?(self.state)
      self.comments = event
      self.send(event)
      # also call save on the model
      # TODO - check if this is really needed
      self.save if self.errors.empty?
    else
      # TODO - IMPORTANT - log that we are ignore the event and what state are we in presently
    end
  end

  def can_delete?
    unless self.program_id.nil?
      self.errors[:base] << "Cannot delete a kit schedule linked to a program"
      return false
    end
    unless self.can_create_on_trigger?
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    end

    return true
  end

  def can_update?
    return true if self.current_user.is? :center_scheduler, :center_id => self.program.center_id
    return true if self.current_user.is? :kit_coordinator, :center_id => self.program.center_id
    return false
  end

  def can_create?(center_ids = self.program.center_id)
    return true if self.current_user.is? :center_scheduler, :for => :any, :center_id => center_ids
    return false
  end

  def can_create_on_trigger?
    return true if self.can_create_reserve? || self.can_create_overdue_or_under_repair?
    return false
  end

  def can_create_reserve?(center_ids = self.kit.center_ids, scope = :any)
    return true if self.current_user.is? :sector_coordinator, :for => scope, :center_id => center_ids
    return false
  end

  def can_create_overdue_or_under_repair?(center_ids = self.kit.center_ids, scope = :any)
    return true if self.current_user.is? :kit_coordinator, :for => scope, :center_id => center_ids
    return false
  end

  def can_delete?
    if (self.state == STATE_RESERVED)
      return true if (self.blocked_by_user == self.current_user) && self.can_create_reserve?
      return true if self.can_create_reserve?(self.kit.center_ids, :all)
    end

    if [STATE_UNAVAILABLE_OVERDUE, STATE_UNDER_REPAIR].include?(self.state)
      return true if (self.blocked_by_user == self.current_user) && self.can_create_overdue_or_under_repair?
      return true if can_create_overdue_or_under_repair?(self.kit.center_ids, :all)
    end

    return false
  end

end
