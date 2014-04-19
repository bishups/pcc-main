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

  STATE_RESERVED    = "Reserved"
  STATE_UNDER_REPAIR = "Under Repair"
  STATE_UNAVAILABLE_OVERDUE = "Overdue"

  STATE_BLOCKED     = "Blocked"
  STATE_ISSUED      = "Issued"
  STATE_ASSIGNED    = "Assigned"
  STATE_OVERDUE     = "Overdue"
  STATE_RETURNED    = "Returned"
  STATE_CANCELLED  = "Cancelled"

  FINAL_STATES = [STATE_RETURNED, STATE_CANCELLED]
  CONNECTED_STATES = [STATE_BLOCKED, STATE_ASSIGNED, STATE_ISSUED, STATE_OVERDUE]
  RESERVED_STATES = [STATE_RESERVED, STATE_UNDER_REPAIR, STATE_UNAVAILABLE_OVERDUE]
  ALL_STATES = RESERVED_STATES + FINAL_STATES + CONNECTED_STATES

  EVENT_RESERVE    = "Reserve"
  EVENT_UNDER_REPAIR = "Under Repair"
  EVENT_UNAVAILABLE_OVERDUE = "Overdue"

  EVENT_BLOCK      = "Block"
  EVENT_ISSUE      = "Issue"
  EVENT_OVERDUE    = "Overdue"
  EVENT_CANCEL     = "Cancel"
  EVENT_RETURNED   = "Returned"

  NOTIFICATIONS = [EVENT_OVERDUE]
  NON_MENU_EVENTS = [EVENT_BLOCK, EVENT_RESERVE, EVENT_UNDER_REPAIR, EVENT_UNAVAILABLE_OVERDUE]
  PROCESSABLE_EVENTS = [EVENT_ISSUE, EVENT_RETURNED, EVENT_CANCEL]

  belongs_to :kit
  belongs_to :program
  belongs_to :blocked_by_user, :class_name => User

  attr_accessor :current_user, :issue_for_schedules
  attr_accessible :program_id, :kit_id,:end_date, :start_date, :state, :comments, :issued_to, :due_date_time, :current_user, :issue_for_schedules

  validates :start_date, :presence => true
  validates :end_date, :presence => true
  validates :kit_id , :presence => true
  validates :state , :presence => true
  validates :program_id, :presence => true, :unless => :kit_reserved?
  validates_uniqueness_of :program_id, :scope => "kit_id", :unless => :kit_reserved_or_cancelled?

  #checking for overlap validation
  validates_with KitScheduleValidator

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


  def initialize(*args)
    super(*args)
  end
   
  state_machine :state , :initial => ::Kit::STATE_AVAILABLE do

    event EVENT_BLOCK do
      transition [::Kit::STATE_AVAILABLE] => STATE_BLOCKED
    end
    before_transition any => STATE_BLOCKED, :do => :before_block
    after_transition any => STATE_BLOCKED, :do => :on_block

    event ::Program::ANNOUNCED do
      transition STATE_BLOCKED => STATE_ASSIGNED
    end

    event EVENT_ISSUE do
      transition [STATE_ASSIGNED] => STATE_ISSUED
    end
    before_transition any => STATE_ISSUED, :do => :before_issue
    after_transition any => STATE_ISSUED, :do => :after_issue

    event EVENT_RETURNED do
      transition [STATE_OVERDUE, STATE_ISSUED] => STATE_RETURNED
    end
    
    event EVENT_OVERDUE do
      transition [STATE_BLOCKED, STATE_ISSUED, STATE_ASSIGNED] => STATE_OVERDUE
    end

    event EVENT_CANCEL do
      transition [STATE_BLOCKED] => STATE_CANCELLED
    end

    event ::Program::DROPPED do
      transition [STATE_BLOCKED] => STATE_CANCELLED
    end

    event ::Program::CANCELLED do
      transition [STATE_ASSIGNED] => STATE_CANCELLED
    end
    before_transition any => STATE_CANCELLED, :do => :comments_present?

    event EVENT_RESERVE do
      transition [::Kit::STATE_AVAILABLE] => STATE_RESERVED
    end

    event EVENT_UNDER_REPAIR do
      transition [::Kit::STATE_AVAILABLE] => STATE_UNDER_REPAIR
    end

    event EVENT_UNAVAILABLE_OVERDUE do
      transition [::Kit::STATE_AVAILABLE] => STATE_UNAVAILABLE_OVERDUE
    end
    before_transition ::Kit::STATE_AVAILABLE => [STATE_RESERVED, STATE_UNDER_REPAIR, STATE_UNAVAILABLE_OVERDUE], :do => :reserve_fields_present?

  end


  def before_block
    self.start_date = self.program.start_date
    self.end_date = self.program.end_date
  end

  def on_block
    self.blocked_by_user = current_user
    self.issue_for_schedules = NIL
  end

  def kit_reserved?
    RESERVED_STATES.include?(self.state)
  end

  def kit_reserved_or_cancelled?
    return true if kit_reserved?
    KitSchedule.find_all_by_program_id_and_kit_id(self.program_id, self.kit_id).each{ |ks|
      next if ks.id == self.id
      return false unless FINAL_STATES.include?(ks.state)
    }
    true
  end

  def comments_present?
    if self.comments.empty?
      self.errors[:comments] << " cannot be blank."
      return false
    end
    true
  end

  def before_issue
    return false unless self.comments_present?
    return true unless self.issue_for_schedules.nil?

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
        self.issue_for_schedules = additional_kit_schedules.class == Array ? additional_kit_schedules : [additional_kit_schedules]
        self.errors[:base] << "Due Date overlaps with other schedules where kit is assigned. Do you want to issue the kit for all the schedules?"
        return false
      end
    end

    true
  end

  def reloaded?
    self.reload
    return true
  rescue ActiveRecord::RecordNotFound
    # TODO - check if to log any error
    return false
  end

  def trigger_overdue(kit_schedules)
    kit_schedules.each { |ks|
      next if !ks.reloaded?
      if [STATE_BLOCKED, STATE_ISSUED, STATE_ASSIGNED].include?(ks.state)
        ks.send(EVENT_OVERDUE)
        ks.save if ks.errors.empty?
      end
    }
  end

  def after_issue
    if !self.issue_for_schedules.nil?
      if self.issue_for_schedules.type == Array
        self.issue_for_schedules << self
      else
        self.issue_for_schedules = [self.issue_for_schedules, self]
      end
      self.delay(:run_at => self.due_date_time).trigger_overdue(self.issue_for_schedules)
    else
      self.delay(:run_at => self.due_date_time).trigger_overdue([self])
    end
    self.issue_for_schedules = NIL
    true
  end

  def can_unblock?
    # to prevent too many error messages on console return early
    if (self.current_user.is? :sector_coordinator, :center_id => self.program.center_id)
      if !self.program.venue_approved?
        self.errors[:base] << "Cannot cancel kit block. Venue linked to the program has already gone for payment request."
        return false
      end
      return true
    end

    if (self.current_user.is? :volunteer_committee, :center_id => self.program.center_id)
      if !self.program.venue_approval_requested?
        self.errors[:base] << "Cannot cancel kit block. Venue linked to the program has already gone for sector coordinator approval."
        return false
      end
      return true
    end

    self.errors[:base] << "Insufficient privileges to update the state."
    false
  end

  def reserve_fields_present?
    if self.comments.blank?
      self.errors[:comments] << " cannot be blank."
      return false
    end
    true
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
  
end
