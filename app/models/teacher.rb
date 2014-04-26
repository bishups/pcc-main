class Teacher < ActiveRecord::Base
  include CommonFunctions

  attr_accessor :current_user
  attr_accessible :current_user

  # There two are hacks, since rails_admin is updating the state of the teacher, instead of the regular controller route
  attr_accessor :last_state
  attr_accessible :last_state

  has_and_belongs_to_many :centers, :after_add => :add_access_privilege, :after_remove  => :remove_access_privilege
  attr_accessible :center_ids, :centers
 # validate :has_centers?

  has_and_belongs_to_many :program_types
  attr_accessible :program_type_ids, :program_types
 # validate :has_program_types?

  belongs_to :user
  attr_accessible :user_id, :user
#  validates :user_id, :uniqueness => true

  belongs_to :zone
  attr_accessible :zone_id, :zone
#  validate :has_zone?

  attr_accessor :comment_category
  attr_accessible :comment_category

  attr_accessible :t_no
#  validates :t_no, :presence => true, :length => { :in => 1..9}
  #validates :email, :uniqueness => true, :format => {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}

  has_many :teacher_schedules
  has_many :timings, through: :teacher_schedules
  attr_accessible :teacher_schedules, :teacher_schedule_ids

  attr_accessible :comments
#  validate :has_comments?

  attr_accessible :state
 # validates :state, :presence => true
 # validate :invalid_state?

  before_save :load_last_state
  after_save  :send_notification

  STATE_UNFIT       = 'Not Fit'
  STATE_UNATTACHED  = 'Not Attached'
  STATE_ATTACHED    = 'Attached'

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

  end


  def load_last_state
    self.last_state = Teacher.find(self.id).state
  rescue ActiveRecord::RecordNotFound
    self.last_state = STATE_UNATTACHED
  end

  def send_notification
    if self.last_state != STATE_ATTACHED && self.state == STATE_ATTACHED
      # TODO - send a notification for teacher attach from here
    end
    if self.last_state == STATE_ATTACHED && self.state != STATE_ATTACHED
      # TODO - send a notification for teacher attach from here
    end
  end

  def before_unattach!
    center_ids = self.center_ids.empty? ? self.zone.center_ids : self.center_ids
    if !self.current_user.is? :zonal_coordinator, :center_id => center_ids
      self.errors[:base] << "Insufficient privileges to update the state."
      false
    end

    if self.in_schedule?
      self.errors.add(:state, " cannot unattach from zone when teacher is linked to a program. Please remove teacher from linked program(s) and try again.")
      return false
    end

    return false unless self.has_comments?

    self.zone_id = nil
    # Also remove all attached centers
    CentersTeachers.where(:teacher_id => self.id).delete_all
    # FIXME - deleting the centers here can be an issue if the transaction fails ...
    true
  end

  def after_unattach
    # if marked unfit remove all published teacher_schedules
    TeacherSchedule.where('teacher_id IS ? AND state IN (?)', self.id, ::TeacherSchedule::STATE_PUBLISHED).delete_all
  end

  def can_mark_unfit?
    center_ids = self.center_ids.empty? ? self.zone.center_ids : self.center_ids
    if !self.current_user.is? :zonal_coordinator, :center_id => center_ids
      self.errors[:base] << "Insufficient privileges to update the state."
      false
    end

    if self.in_schedule?
      self.errors.add(:state, " cannot mark unfit when teacher is linked to a program. Please remove teacher from linked program(s) and try again.")
      return false
    end

    return false unless self.has_comments?
    true
  end

  def on_unfit
    # if marked unfit remove all published teacher_schedules
    TeacherSchedule.where('teacher_id IS AND state IN (?)', self.id, ::TeacherSchedule::STATE_PUBLISHED).delete_all

    # Also remove all attached centers
    CentersTeachers.where(:teacher_id => self.id).delete_all
  end


  def in_schedule?
    self.teacher_schedules.each { |ts|
      return true if (::ProgramTeacherSchedule::CONNECTED_STATES).include?(ts.state)
    }
    false
  end


  def has_comments?
    if (self.state == STATE_UNFIT) && self.comments.blank?
      self.errors.add(:comments, " needed if the teacher is marked unfit.")
      return false
    end
    true
  end

  def has_centers?
    self.errors.add(:centers, " needed if teacher attached to a zone.") if !self.zone.blank? && self.centers.blank? && (self.state != STATE_UNFIT)
    self.errors.add(:zone, " needed if teacher attached to center(s). To un-attach from a zone, first remove the center(s).") if self.zone.blank? && !self.centers.blank? && (self.state != STATE_UNFIT)
    self.errors.add(:centers, " should belong to one sector.") if self.centers && !::Sector::all_centers_in_one_sector?(self.centers)
    self.errors.add(:centers, " should belong to specified zone.") if self.centers && self.zone && (self.centers[0] && self.centers[0].sector.zone != self.zone)
  end


  def has_program_types?
    self.errors.add(:program_types, "Teacher needs to be associated to program type(s).") if self.program_types.blank?
  end

  def has_zone?
    self.errors.add(:zone, " cannot be blank when teacher is attached.") if self.zone.blank? && (self.state == STATE_ATTACHED)
    self.errors.add(:zone, " cannot be marked blank when teacher is linked to a program.") if self.zone.blank? && self.in_schedule?
    self.errors.add(:zone, " need to be blank when teacher is marked unattached.") if !self.zone.blank? && (self.state == STATE_UNATTACHED)
  end

  def invalid_state?
    self.errors.add(:state, " cannot be marked unfit when teacher is linked to a program.") if (self.state == STATE_UNFIT) && self.in_schedule?
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
    center_ids = self.center_ids.empty? ? self.zone.center_ids : self.center_ids
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
      # to get the current user from the rails-admin view
      field :current_user, :hidden do
        read_only true
        default_value do
          bindings[:object].current_user = bindings[:view].current_user
        end
      end
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
        # TODO - humanize the strings below, without breaking the state_machine functionality
        enum do
          [STATE_UNFIT, STATE_UNATTACHED, STATE_ATTACHED]
        end
        read_only do
          not bindings[:controller].current_user.is?(:super_admin)
        end
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
