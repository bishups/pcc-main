class Teacher < ActiveRecord::Base
  include CommonFunctions

  has_many :activity_logs, :as => :model, :inverse_of => :model, :dependent => :destroy
  has_many :notification_logs, :as => :model, :inverse_of => :model, :dependent => :destroy

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
  validate :has_centers?, :unless => :full_time?

 # Commented for now as there is no definition for this
 # validate :is_unfit?

  has_and_belongs_to_many :program_types
  attr_accessible :program_type_ids, :program_types
  validate :has_program_types?

  belongs_to :user
  attr_accessible :user_id, :user
  validates :user_id, :presence => true
  validates_uniqueness_of :user_id, :scope => :deleted_at


  belongs_to :zone
  attr_accessible :zone_id, :zone
  validate :has_zone?

  attr_accessor :comment_category
  attr_accessible :comment_category

  attr_accessible :t_no
  validates :t_no, :presence => true, :length => { :in => 1..9}
#  validates :email, :uniqueness => true, :format => {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}

  has_many :teacher_schedules, :dependent => :destroy
  has_many :timings, through: :teacher_schedules
  attr_accessible :teacher_schedules, :teacher_schedule_ids

  attr_accessible :comments
  validate :check_comments?

  attr_accessible :state, :full_time
  validates :state, :presence => true
  validate :invalid_state?


  #before_save :load_last_state
  # NOTE - please add any additional post-save cleanup to the function below.
  # Do not add any new function. This is because we are manipulating dirty flag
  # in the function below, due to some HABTM HACK, and *_change when called in another
  # chained after_save function will fail
  after_save :after_save_cleanup

  STATE_UNFIT       = 'Not Fit'
  STATE_UNATTACHED  = 'Not Attached'
  STATE_ATTACHED    = 'Attached'

  FINAL_STATES = [STATE_UNATTACHED]

  # The attach functionality need to be exercised through the admin interface only,
  # since zone(s) and center(s) need to be linked again
  # It is still defined here only for logging and notification purposes
  EVENT_ATTACH      = 'Attach '

  EVENT_UNATTACH    = 'Unattach'
  EVENT_UNFIT       = 'Unfit'

  PROCESSABLE_EVENTS = [
      EVENT_UNATTACH, EVENT_UNFIT
  ]

  EVENTS_WITH_COMMENTS = [EVENT_UNFIT, EVENT_UNATTACH]
  EVENTS_WITH_FEEDBACK = []

  state_machine :state, :initial => STATE_UNATTACHED do

    event EVENT_UNATTACH do
      transition [STATE_ATTACHED, STATE_UNFIT] => STATE_UNATTACHED, :if => lambda {|t| t.current_user.is? :zao, :center_id => t.center_ids }
    end
    before_transition any => STATE_UNATTACHED, :do => :before_unattach!
    after_transition any => STATE_UNATTACHED, :do => :after_unattach

    event EVENT_UNFIT do
      transition [STATE_ATTACHED] => STATE_UNFIT, :if => lambda {|t| t.current_user.is? :zao, :center_id => t.center_ids }
    end
    before_transition any => STATE_UNFIT, :do => :can_mark_unfit?
    after_transition any => STATE_UNFIT, :do => :on_unfit

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

    after_transition any => any do |object, transition|
      object.store_last_update!(object.current_user, transition.from, transition.to, transition.event)
    end

  end

  #def load_last_state
  #  self.last_state = Teacher.find(self.id).state
  #rescue ActiveRecord::RecordNotFound
  #  self.last_state = STATE_UNATTACHED
  #end

  def after_save_cleanup
    changes = self.changes
    return if changes.nil? || changes.empty?

    # STEP-1 : First identify all the changed values that we are interested in
    current_state = self.state
    state_changed = changes.has_key?(:state)
    last_state = self.changes[:state][0] if state_changed

    current_zone = self.zone
    zone_changed = changes.has_key?(:zone)
    last_zone = self.changes[:zone][0] if zone_changed

    full_time_changed = changes.has_key?(:full_time)

    # STEP-2 : HACK to handle HABTM in after_save
    # HACK - all this making the program_types and centers dirty and reloading the object
    # due to open rails bug attr_writer :hen trying to save a model with habtm in after_create
    # https://rails.lighthouseapp.com/projects/8994/tickets/4553-habtm-association-failure-to-save-in-join-table-with-after_create-callback
    if state_changed or ((zone_changed or full_time_changed) and self.full_time?)
      program_types = self.program_types
      centers = self.centers
      self.reload
      self.program_types = program_types
      self.centers = centers
    end

    # STEP-3 : Now make the changes ...
    # Change # 1 - delete published schedules for teacher changed from part-time to full-time OR when teacher is Un-attached
    if self.has_published_schedules?
      self.delete_published_schedules if (full_time_changed and self.full_time?) or (state_changed and last_state == STATE_ATTACHED)
    end

    # Change # 2 - update centers for full time teacher whose zone was changed, or who was earlier part-time teacher
    if (zone_changed or full_time_changed) and self.full_time?
      if !(current_zone.nil? or current_zone.blank?) and current_state == STATE_ATTACHED
        self.centers = current_zone.centers
      else
        self.centers = []
      end
      self.save
    end

    # Change # 3 - send out notifications if either un-attached, or attached
    if state_changed
      if current_state == STATE_ATTACHED
        event = EVENT_ATTACH
      elsif current_state == STATE_UNATTACHED and last_state == STATE_ATTACHED
        event = EVENT_UNATTACH
      elsif current_state == STATE_UNFIT and last_state == STATE_ATTACHED
        event = EVENT_UNFIT
      else
        event = nil
      end

      unless event.nil?
        # TODO - see how we can get the current_user here?
        self.store_last_update!(nil, last_state, current_state, nil)
        self.save
        self.notify(last_state, current_state, event, self.centers, self)
      end
    end
  end


  def before_unattach!
    center_ids = self.center_ids.empty? ? self.zone.center_ids : self.center_ids
    if !User.current_user.is? :zao, :center_id => center_ids
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
    self.delete_published_schedules
  end

  def can_mark_unfit?
    center_ids = self.center_ids.empty? ? self.zone.center_ids : self.center_ids
    if !User.current_user.is? :zao, :center_id => center_ids
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
    # if marked unfit remove all future published teacher_schedules
    self.delete_published_schedules

    # Also remove all attached centers
    CentersTeachers.where(:teacher_id => self.id).delete_all
  end

  def has_published_schedules?
    TeacherSchedule.where('(teacher_id = ? OR teacher_id IS NULL) AND state IN (?)', self.id, ::TeacherSchedule::STATE_PUBLISHED).count > 0
  end

  def delete_published_schedules
    TeacherSchedule.where('teacher_id = ? AND state IN (?) AND start_date >= ?', self.id, ::TeacherSchedule::STATE_PUBLISHED, Time.zone.now.to_date).delete_all
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
    self.errors.add(:centers, " needed if teacher attached to a zone.") if !self.zone.blank? && self.centers.blank? && (self.state != STATE_UNFIT) and (!self.full_time?)
    self.errors.add(:zone, " needed if teacher attached to center(s). To un-attach from a zone, first remove the center(s).") if self.zone.blank? && !self.centers.blank? and (!self.full_time?)
    #self.errors.add(:centers, " should belong to one sector.") if self.centers && !::Sector::all_centers_in_one_sector?(self.centers)
    self.errors.add(:centers, " should belong to one zone.") if !::Zone::all_centers_in_one_zone?(self.centers)
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
    self.errors.add(:state, " cannot be marked unfit when teacher is attached to center(s). To mark unfit, first remove the center(s).") if (self.state == STATE_UNFIT) and (!self.full_time?)
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
    if self.full_time?
      return true if User.current_user.is? :full_time_teacher_scheduler, :for => :any, :center_id => self.center_ids
      return true if User.current_user.is? :zao, :for => :any, :center_id => self.center_ids
    end
    return true if User.current_user.is? :center_scheduler, :for => :any, :center_id => self.center_ids
    return true if User.current_user.is? :teacher_training_department, :for => :any, :center_id => self.center_ids
    return true if self.is_current_user?
    return false
  end

  def can_view_schedule?
    if self.full_time?
      return true if (User.current_user.is? :full_time_teacher_scheduler, :for => :any, :center_id => self.center_ids)
      return true if (User.current_user.is? :zao, :for => :any, :center_id => self.center_ids)
    else
      return true if (User.current_user.is? :center_scheduler, :for => :any, :center_id => self.center_ids)
    end
    return true if self.is_current_user?
    return false
  end

  # HACK - to route the call through teacher object from the UI.
  def can_create_schedule?
    teacher_schedule = TeacherSchedule.new
    teacher_schedule.teacher = self
    teacher_schedule.current_user = User.current_user
    return teacher_schedule.can_create?
  end

  # HACK - to route the call through teacher object from the UI.
  def can_create_program_schedule?
    program_teacher_schedule = ProgramTeacherSchedule.new
    program_teacher_schedule.current_user = User.current_user
    program_teacher_schedule.teacher = self
    return program_teacher_schedule.can_create?(self.center_ids)
  end

  def can_update?
    center_ids = []
    if self.center_ids.nil? || self.center_ids.empty?
      center_ids = self.zone.center_ids unless self.zone.nil?
    else
      center_ids = self.center_ids
    end
    return true if User.current_user.is? :zao, :center_id => center_ids
    return false
  end

  def is_current_user?
    User.current_user == self.user
  end

  def can_create(options={})
    if options.has_key?(:any) && options[:any] == true
      center_ids = []
    else
      center_ids = self.center_ids
    end

    return false
    #return true if User.current_user.is? :venue_coordinator, :center_id => center_ids
  end

  def can_be_blocked_by?(program, co_teacher)
    if self.full_time?
      # check if teacher has matching program_type, or is a co_teacher
      return false unless (self.program_types.include?(program.program_donation.program_type) or co_teacher)
      ts = TeacherSchedule.new
      ts.program = program
      ts.teacher_id = self.id
      program.timing_ids.each { |timing_id|
        ts.timing_id = timing_id
        # if program schedule does not overlap any other schedule for the teacher
        return false if ts.schedule_overlaps?
      }
    else
      # check if teacher has matching program_type
      return false unless self.program_types.include?(program.program_donation.program_type)
      program.timings.each {|t|
        ts = self.teacher_schedules.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").where('teacher_schedules.start_date <= ? AND teacher_schedules.end_date >= ? AND teacher_schedules.timing_id = ? AND teacher_schedules.state = ? AND (centers_teacher_schedules.center_id = ? OR centers_teacher_schedules.center_id IS NULL)',
                                                                                                                                                          program.start_date.to_date, program.end_date.to_date, t.id,
                                                                                                                                                          ::TeacherSchedule::STATE_AVAILABLE, program.center_id).first
        return false if ts.nil?
      }
    end
    return true
  end

  def full_time?
    return self.full_time
  end

  def url
    Rails.application.routes.url_helpers.teacher_url(self)
  end

  def friendly_first_name_for_email
    "Teacher ##{self.id}"
  end

  def friendly_second_name_for_email
    " #{self.user.fullname}"
  end

  def friendly_name_for_sms
    "Teacher ##{self.id} #{self.user.firstname}"
  end


  rails_admin do
    list do
      field :t_no
      field :user
      field :full_time
      field :state
      field :zone
      field :program_types
      field :centers
    end
    edit do
      field :user  do
       # inverse_of :teachers
       # inline_edit false
       # inline_add false
        read_only do
         true # not bindings[:controller].current_user.is?(:super_admin) or bindings[:controller].current_user.is?(:teacher_training_department)
        end
      end
      field :t_no do
        read_only do
          not ( bindings[:controller].current_user.is?(:super_admin) or bindings[:controller].current_user.is?(:teacher_training_department) )
        end
      end
      field :full_time do
        read_only do
          not ( bindings[:controller].current_user.is?(:super_admin) or bindings[:controller].current_user.is?(:teacher_training_department) )
        end
      end
      field :state, :enum do
        label "Status"
        enum do
          # This is a HACK to represent some sort of state machine through rails_admin
          # if bindings[:object].state == STATE_UNATTACHED && (bindings[:controller].current_user.is? :super_admin, :center_id => bindings[:object].center_ids)
          #   [STATE_UNATTACHED, STATE_ATTACHED]
          # elsif bindings[:object].state == STATE_UNATTACHED && (bindings[:controller].current_user.is? :zao, :center_id => bindings[:object].center_ids)
          #   [STATE_UNATTACHED]
          # elsif bindings[:object].state == STATE_ATTACHED && (bindings[:controller].current_user.is? :zao, :center_id => bindings[:object].center_ids)
          #   [STATE_UNATTACHED, STATE_ATTACHED, STATE_UNFIT]
          # elsif bindings[:object].state == STATE_UNFIT && (bindings[:controller].current_user.is? :zao, :center_id => bindings[:object].center_ids)
          #   [STATE_UNATTACHED, STATE_UNFIT]
          # elsif (bindings[:controller].current_user.is? :teacher_training_department, :center_id => bindings[:object].center_ids)
          #   [STATE_UNATTACHED]
          # else
          #   []
          # end

          # Changed by Senthil based on discussion wiht Radha Akka. Currently displaying all the states and this can changed only by teacher training department.
          # This will be read only for all other users.
          [STATE_UNATTACHED, STATE_ATTACHED, STATE_UNFIT]
        end
        read_only do
          # user.is? is always returning true for super admin even if we a super admin is? :teacher_training_department,
          # but here we want to make this field read, only if use is super admin.
          if bindings[:controller].current_user.is?(:super_admin)
            false #true - Temporarily allowing user super admin to create Teachers.
          elsif bindings[:controller].current_user.is?(:teacher_training_department)
            false
          else
            true
          end
        end
      end
      field :zone  do
       # inverse_of :teachers
        inline_edit false
        inline_add false
        read_only do
          # user.is? is always returning true for super admin even if we a super admin is? :teacher_training_department,
          # but here we want to make this field read, only if use is super admin.
          if bindings[:controller].current_user.is?(:super_admin)
            false #true - Temporarily allowing user super admin to create Teachers.
          elsif bindings[:controller].current_user.is?(:teacher_training_department)
            false
          else
            true
          end
        end
      end
      field :program_types  do
        inverse_of :teachers
        #inline_edit false
        inline_add false
        read_only do
          # user.is? is always returning true for super admin even if we a super admin is? :teacher_training_department,
          # but here we want to make this field read, only if use is super admin.
          if bindings[:controller].current_user.is?(:super_admin)
            false #true - Temporarily allowing user super admin to create Teachers.
            false #true - Temporarily allowing user super admin to create Teachers.
          elsif bindings[:controller].current_user.is?(:teacher_training_department)
            false
          else
            true
          end
        end
      end
      field :centers do
        inverse_of  :teachers
        #inline_edit false
        inline_add false
        visible do
          not ( bindings[:object].full_time? )
        end
        # read_only do
        #   # user.is? is always returning true for super admin even if we a super admin is? :teacher_training_department,
        #   # but here we want to make this field read, only if use is super admin.
        #   bindings[:controller].current_user.is?(:teacher_training_department) if not bindings[:controller].current_user.is?(:super_admin)
        # end
        associated_collection_cache_all true  # REQUIRED if you want to SORT the list as below
        associated_collection_scope do
          # bindings[:object] & bindings[:controller] are available, but not in scope's block!
        accessible_centers = bindings[:controller].current_user.accessible_centers(:zao)
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
    create do
      configure :user  do
        inverse_of :teachers
        inline_edit false
        inline_add false
        read_only do
          not ( bindings[:controller].current_user.is?(:super_admin) or bindings[:controller].current_user.is?(:teacher_training_department) )
        end
      end
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
