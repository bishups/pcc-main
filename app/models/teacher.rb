class Teacher < ActiveRecord::Base
  include CommonFunctions

  acts_as_paranoid

  attr_accessor :current_user
  attr_accessible :current_user

  # There two are hacks, since rails_admin is updating the state of the teacher, instead of the regular controller route
  attr_accessor :last_state
  attr_accessible :last_state

  belongs_to :last_updated_by_user, :class_name => User
  attr_accessible :last_update, :last_updated_at

  has_and_belongs_to_many :centers, :after_add => :add_access_privilege, :after_remove  => :remove_access_privilege
  attr_accessible :center_ids, :centers
  validate :has_centers?

  validate :is_unfit?

  has_and_belongs_to_many :program_types
  attr_accessible :program_type_ids, :program_types
  validate :has_program_types?

  belongs_to :user
  attr_accessible :user_id, :user
  validates :user_id, :uniqueness => true

  belongs_to :zone
  attr_accessible :zone_id, :zone
  validate :has_zone?

  attr_accessor :comment_category
  attr_accessible :comment_category

  attr_accessible :t_no
  validates :t_no, :presence => true, :length => { :in => 1..9}
  validates :email, :uniqueness => true, :format => {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}

  has_many :teacher_schedules
  has_many :timings, through: :teacher_schedules
  attr_accessible :teacher_schedules, :teacher_schedule_ids

  attr_accessible :comments
  validate :check_comments?

  attr_accessible :state
  validates :state, :presence => true
  validate :invalid_state?

  before_save :load_last_state
  after_save  :send_notification

  STATE_UNFIT       = 'Not Fit'
  STATE_UNATTACHED  = 'Not Attached'
  STATE_ATTACHED    = 'Attached'

  FINAL_STATES = [STATE_UNATTACHED]

  # The attach functionality need to be exercised through the admin interface only,
  # since zone(s) and center(s) need to be linked again
  # EVENT_ATTACH      = 'Attach '

  EVENT_UNATTACH    = 'Unattach'
  EVENT_UNFIT       = 'Unfit'

  PROCESSABLE_EVENTS = [
      EVENT_UNATTACH, EVENT_UNFIT
  ]

  EVENTS_WITH_COMMENTS = [EVENT_UNFIT, EVENT_UNATTACH]
  EVENTS_WITH_FEEDBACK = []

  state_machine :state, :initial => STATE_UNATTACHED do

    event EVENT_UNATTACH do
      # TODO - if not transitioning in state machine, see if need to pass back some error message
      transition [STATE_ATTACHED, STATE_UNFIT] => STATE_UNATTACHED, :if => lambda {|t| t.current_user.is? :zonal_coordinator, :center_id => t.center_ids }
    end
    before_transition any => STATE_UNATTACHED, :do => :before_unattach!
    after_transition any => STATE_UNATTACHED, :do => :after_unattach

    event EVENT_UNFIT do
      transition [STATE_ATTACHED] => STATE_UNFIT, :if => lambda {|t| t.current_user.is? :zonal_coordinator, :center_id => t.center_ids }
    end
    before_transition any => STATE_UNFIT, :do => :can_mark_unfit?
    after_transition any => STATE_UNFIT, :do => :on_unfit

    # check for comments, before any transition
    before_transition any => any do |object, transition|
      if EVENTS_WITH_COMMENTS.include?(transition.event) && !object.has_comments?
        return false
      end
      if EVENTS_WITH_FEEDBACK.include?(transition.event) && !object.has_feedback?
        return false
      end
    end

    after_transition any => any do |object, transition|
      object.store_last_update!(object.current_user, transition.from, transition.to, transition.event)
    end

  end

  def load_last_state
    self.last_state = Teacher.find(self.id).state
  rescue ActiveRecord::RecordNotFound
    self.last_state = STATE_UNATTACHED
  end

  # HACK - a common place, for both rails_admin and state_machine,  to send notifications
  def send_notification
    if self.last_state != STATE_ATTACHED && self.state == STATE_ATTACHED
      # HACK - since we can attach only from rails_admin, store the last update
      # TODO - see how we can get the current_user here?
      object.store_last_update!(nil, self.last_state, self.state, nil)
      object.notify(:any, STATE_ATTACHED, :any, self.center_ids)
    end
    if self.last_state == STATE_ATTACHED && self.state != STATE_ATTACHED
      # if we have published TeacherSchedules, means we are coming through the rails_admin
      if TeacherSchedule.where('teacher_id IS ? AND state IN (?)', self.id, ::TeacherSchedule::STATE_PUBLISHED).count > 0
        # remove all published teacher schedules
        TeacherSchedule.where('teacher_id IS ? AND state IN (?)', self.id, ::TeacherSchedule::STATE_PUBLISHED).delete_all
        # HACK - store the last update for rails_admin
        # TODO - see how we can get the current_user here?
        object.store_last_update!(nil, self.last_state, self.state, nil)
      end
      object.notify(STATE_ATTACHED, :any, :any, self.center_ids)
    end

  end


  def before_unattach!
    center_ids = self.center_ids.empty? ? self.zone.center_ids : self.center_ids
    if !self.current_user.is? :zonal_coordinator, :center_id => center_ids
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    end

    if self.in_schedule?
      self.errors.add(:state, " cannot unattach from zone when teacher is linked to a program. Please remove teacher from linked program(s) and try again.")
      return false
    end

    self.zone_id = nil
    # Also remove all attached centers
    CentersTeachers.where(:teacher_id => self.id).delete_all
    # FIXME - deleting the centers here can be an issue if the transaction fails ...
    return true
  end

  def after_unattach
    # if marked unfit remove all published teacher_schedules
    TeacherSchedule.where('teacher_id IS ? AND state IN (?)', self.id, ::TeacherSchedule::STATE_PUBLISHED).delete_all
  end

  def can_mark_unfit?
    center_ids = self.center_ids.empty? ? self.zone.center_ids : self.center_ids
    if !self.current_user.is? :zonal_coordinator, :center_id => center_ids
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    end

    if self.in_schedule?
      self.errors.add(:state, " cannot mark unfit when teacher is linked to a program. Please remove teacher from linked program(s) and try again.")
      return false
    end

    return true
  end

  def on_unfit
    # if marked unfit remove all published teacher_schedules
    TeacherSchedule.where('teacher_id IS ? AND state IN (?)', self.id, ::TeacherSchedule::STATE_PUBLISHED).delete_all

    # Also remove all attached centers
    CentersTeachers.where(:teacher_id => self.id).delete_all
  end


  def in_schedule?
    self.teacher_schedules.each { |ts|
      return true if ts.is_connected?
    }
    return false
  end

  # This is a hack to take care of rails_admin
  def check_comments?
    self.errors.add(:comments, " needed if the teacher is marked unfit/ unattached.") if [STATE_UNFIT, STATE_UNATTACHED].include?(self.state) && !self.has_comments?
  end

  def has_centers?
    self.errors.add(:centers, " needed if teacher attached to a zone.") if !self.zone.blank? && self.centers.blank? && (self.state != STATE_UNFIT)
    self.errors.add(:zone, " needed if teacher attached to center(s). To un-attach from a zone, first remove the center(s).") if self.zone.blank? && !self.centers.blank?
    self.errors.add(:centers, " should belong to one sector.") if self.centers && !::Sector::all_centers_in_one_sector?(self.centers)
    self.errors.add(:centers, " should belong to specified zone.") if self.centers && self.zone && (self.centers[0] && self.centers[0].sector.zone != self.zone)
  end


  def has_program_types?
    self.errors.add(:program_types, "Teacher needs to be associated to program type(s).") if self.program_types.blank?
  end

  def has_zone?
    self.errors.add(:zone, " cannot be blank when teacher is attached/ unfit.") if self.zone.blank? && [STATE_UNFIT, STATE_ATTACHED].include?(self.state)
    self.errors.add(:zone, " need to be blank when teacher is unattached.") if !self.zone.blank? && (self.state == STATE_UNATTACHED)
  end

  def invalid_state?
    self.errors.add(:state, " cannot be marked unfit when teacher is linked to a program.") if (self.state == STATE_UNFIT) && self.in_schedule?
    self.errors.add(:state, " cannot be marked unattached when teacher is linked to a program.") if (self.state == STATE_UNATTACHED) && self.in_schedule?
  end


  def add_access_privilege(center)
    role = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:teacher][:text])
    AccessPrivilege.create({ :role_id => role.id, :user_id => self.user.id, :resource_id => center.id, :resource_type => "Center" })
  end


  def remove_access_privilege(center)
    role = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:teacher][:text])
    AccessPrivilege.destroy_all({ :role_id => role.id, :user_id => self.user.id, :resource_id => center.id, :resource_type => "Center" })
  end


  def can_view?
    return true if self.current_user.is? :center_scheduler, :for => :any, :center_id => self.center_ids
    return true if self.is_current_user?
    return false
  end

  def can_view_schedule?
    return true if self.current_user.is? :center_scheduler, :for => :any, :center_id => self.center_ids
    return true if self.is_current_user?
    return false
  end

  # TODO - this is a hack, to route the call through teacher object from the UI.
  def can_create_schedule?
    teacher_schedule = TeacherSchedule.new
    teacher_schedule.teacher = self
    teacher_schedule.current_user = self.current_user
    return teacher_schedule.can_create?
  end

  def can_update?
    center_ids = []
    if self.center_ids.nil? || self.center_ids.empty?
      center_ids = self.zone.center_ids unless self.zone.nil?
    else
      center_ids = self.center_ids
    end
    return true if self.current_user.is? :zonal_coordinator, :center_id => center_ids
    return false
  end

  def is_current_user?
    self.current_user == self.user
  end

  def can_create(options={})
    if options.has_key?(:any) && options[:any] == true
      center_ids = []
    else
      center_ids = self.center_ids
    end

    return false
    #return true if self.current_user.is? :venue_coordinator, :center_id => center_ids
  end



  rails_admin do
    list do
      field :t_no
      field :user
      field :state
      field :zone
      field :program_types
      field :centers
    end
    edit do
      field :user  do
        inverse_of :teachers
        inline_edit false
        inline_add false
        read_only do
          not bindings[:controller].current_user.is?(:super_admin)
        end
      end
      field :t_no do
        read_only do
          not bindings[:controller].current_user.is?(:super_admin)
        end
      end
      field :state, :enum do
        label "Status"
        enum do
          # This is a HACK to represent some sort of state machine through rails_admin
          if bindings[:object].state == STATE_UNATTACHED && (bindings[:controller].current_user.is? :super_admin, :center_id => bindings[:object].center_ids)
            [STATE_UNATTACHED, STATE_ATTACHED]
          elsif bindings[:object].state == STATE_UNATTACHED && (bindings[:controller].current_user.is? :zonal_coordinator, :center_id => bindings[:object].center_ids)
            [STATE_UNATTACHED]
          elsif bindings[:object].state == STATE_ATTACHED && (bindings[:controller].current_user.is? :zonal_coordinator, :center_id => bindings[:object].center_ids)
            [STATE_UNATTACHED, STATE_ATTACHED, STATE_UNFIT]
          elsif bindings[:object].state == STATE_UNFIT && (bindings[:controller].current_user.is? :zonal_coordinator, :center_id => bindings[:object].center_ids)
            [STATE_UNATTACHED, STATE_UNFIT]
          else
            []
          end
        end
        #read_only do
        #  not bindings[:controller].current_user.is?(:super_admin)
        #end
      end
      field :zone  do
       # inverse_of :teachers
        inline_edit false
        inline_add false
      end
      field :program_types  do
        inverse_of :teachers
        #inline_edit false
        inline_add false
        read_only do
          not bindings[:controller].current_user.is?(:super_admin)
        end
      end
      field :centers do
        inverse_of  :teachers
        #inline_edit false
        inline_add false
        associated_collection_cache_all true  # REQUIRED if you want to SORT the list as below
        associated_collection_scope do
          # bindings[:object] & bindings[:controller] are available, but not in scope's block!
          accessible_centers = bindings[:controller].current_user.accessible_centers(:zonal_coordinator)
          Proc.new { |scope|
            # scoping all Players currently, let's limit them to the team's league
            # Be sure to limit if there are a lot of Players and order them by position
            # scope = scope.where(:id => accessible_centers )
            scope = scope.where(:id => accessible_centers )
          }
        end
      end
      field :comments
    end
  end


=begin
  def centers
    list = []
    role = :teacher
    self.user.access_privileges.each do |ap|
      if ap.resource.class.name.demodulize == "Center"
        resource = [ap.resource]
      elsif ap.resource.class.name.demodulize == "Sector" || ap.resource.class.name.demodulize == "Zone"
        resource = ap.resource.centers
      else
        resource = []
      end

      # if role matches
      if role == Role.find_by_id(ap.role_id)
        list.push(*resource)
      end
    end
    list
  end
=end


end
