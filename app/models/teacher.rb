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
  validate :has_centers? , :unless => :full_time?

  has_and_belongs_to_many :zones, :join_table => "zones_teachers", :before_add => :before_add_zone, :after_add => :after_add_zone, :before_remove  => :before_remove_zone, :after_remove  => :after_remove_zone
  attr_accessible :zone_ids, :zones
  #validate :has_zone?


  # Commented for now as there is no definition for this
 # validate :is_unfit?

  has_and_belongs_to_many :program_types
  attr_accessible :program_type_ids, :program_types
  validate :has_program_types?

  has_and_belongs_to_many :co_teacher_program_types, class_name: "ProgramType", join_table: "program_types_co_teachers"
  attr_accessible :co_teacher_program_type_ids, :co_teacher_program_types

  has_and_belongs_to_many :organizing_teacher_program_types, class_name: "ProgramType", join_table: "program_types_organizing_teachers"
  attr_accessible :organizing_teacher_program_type_ids, :organizing_teacher_program_types

  has_and_belongs_to_many :hall_teacher_program_types, class_name: "ProgramType", join_table: "program_types_hall_teachers"
  attr_accessible :hall_teacher_program_type_ids, :hall_teacher_program_types

  has_and_belongs_to_many :initiation_teacher_program_types, class_name: "ProgramType", join_table: "program_types_initiation_teachers"
  attr_accessible :initiation_teacher_program_type_ids, :initiation_teacher_program_types

  PROGRAM_TYPES = {
      ::TeacherSchedule::ROLE_MAIN_TEACHER => "program_types",
      ::TeacherSchedule::ROLE_CO_TEACHER => "co_teacher_program_types",
      ::TeacherSchedule::ROLE_ORGANIZING_TEACHER => "organizing_teacher_program_types",
      ::TeacherSchedule::ROLE_HALL_TEACHER => "hall_teacher_program_types",
      ::TeacherSchedule::ROLE_INITIATION_TEACHER => "initiation_teacher_program_types"
  }

  PROGRAM_TYPES_TABLES = {
      ::TeacherSchedule::ROLE_MAIN_TEACHER => "program_types_teachers",
      ::TeacherSchedule::ROLE_CO_TEACHER => "program_types_co_teachers",
      ::TeacherSchedule::ROLE_ORGANIZING_TEACHER => "program_types_organizing_teachers",
      ::TeacherSchedule::ROLE_HALL_TEACHER => "program_types_hall_teachers",
      ::TeacherSchedule::ROLE_INITIATION_TEACHER => "program_types_initiation_teachers",
  }

  belongs_to :user
  attr_accessible :user_id, :user
  validates :user_id, :presence => true
  validates_uniqueness_of :user_id, :scope => :deleted_at


  attr_accessor :comment_category
  attr_accessible :comment_category

  attr_accessible :t_no
  validates :t_no, :presence => true, :length => { :in => 1..9}
#  validates :email, :uniqueness => true, :format => {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}

  has_many :teacher_schedules, :dependent => :destroy
  has_many :timings, through: :teacher_schedules
  attr_accessible :teacher_schedules, :teacher_schedule_ids

  attr_accessible :comments, :additional_comments

  after_initialize :init

  attr_accessible :state
  validates :state, :presence => true

  attr_accessible :full_time

  #before_save :load_last_state
  #before_save :before_save_set_state
  # NOTE - please add any additional post-save cleanup to the function below.
  # Do not add any new function. This is because we are manipulating dirty flag
  # in the function below, due to some HABTM HACK, and *_change when called in another
  # chained after_save function will fail
  after_save :after_save_cleanup

  STATE_UNATTACHED  = 'Not Attached'
  STATE_ATTACHED    = 'Attached'

  FINAL_STATES = []

  # The attach functionality need to be exercised through the admin interface only,
  # since zone(s) and center(s) need to be linked again
  # It is still defined here only for logging and notification purposes
  EVENT_ATTACH      = 'Attach '
  EVENT_UNATTACH    = 'Unattach'

  PROCESSABLE_EVENTS = []



  def init
    self.state  ||= STATE_UNATTACHED
  end

  #state_machine :state, :initial => STATE_UNATTACHED do
  #end

  #def load_last_state
  #  self.last_state = Teacher.find(self.id).state
  #rescue ActiveRecord::RecordNotFound
  #  self.last_state = STATE_UNATTACHED
  #end

  def before_add_zone(zone)
    self.state = STATE_ATTACHED if self.zones.blank?
    return true
  end

  def after_add_zone(zone)
    # for full-time, add centers corresponding to zone
    if self.full_time?
      # remove once to avoid duplicates
      self.centers -= zone.centers
      # add the centers
      self.centers += zone.centers
    end
  end

  def before_remove_zone(zone)
    if self.in_schedule?(zone)
      self.errors.add(:zones, " #{zone.name} cannot be un-attached. Teacher is linked to a program. Please remove teacher from linked program(s) and try again.")
      return false
    end

    # set the new value of states
    self.state = STATE_UNATTACHED if self.zones == [zone]
    return true
  end

  def after_remove_zone(zone)
    # for full-time, remove centers corresponding to zone
    self.centers -= zone.centers if self.full_time?
  end

  def after_save_cleanup
    changes = self.changes
    return if changes.blank?

    # STEP-1 : First identify all the changed values that we are interested in
    current_state = self.state
    state_changed = changes.has_key?(:state)
    last_state = self.changes[:state][0] if state_changed

    full_time_changed = changes.has_key?(:full_time)

    # STEP-2 : HACK to handle HABTM in after_save
    # HACK - all this making the program_types and centers dirty and reloading the object
    # due to open rails bug attr_writer :hen trying to save a model with habtm in after_create
    # https://rails.lighthouseapp.com/projects/8994/tickets/4553-habtm-association-failure-to-save-in-join-table-with-after_create-callback
    if state_changed or (full_time_changed and self.full_time?)
      temp_program_types = {}
      ::Teacher::PROGRAM_TYPES.each{ |role, value|
        temp_program_types[role] = eval("self." + value)
      }
      #program_types = self.program_types
      centers = self.centers
      zones = self.zones
      self.reload
      ::Teacher::PROGRAM_TYPES.each{ |role, value|
        eval("self.#{value} = temp_program_types[\"#{role}\"]")
      }
      #self.program_types = program_types
      self.centers = centers
      self.zones = zones
    end

    # STEP-3 : Now make the changes ... for teacher changed from part-time to full-time
    if (full_time_changed and self.full_time?)
      # Change # 1 - delete published schedules
      self.delete_published_schedules if self.has_published_schedules?

    # Change # 2 - update centers for attached zones
      self.centers = []
      self.zones.each { |zone|
        self.centers += zone.centers
      }
      self.save
    end

    # STEP - 4 - send out notifications if either un-attached, or attached
    if state_changed
      if current_state == STATE_ATTACHED
        event = EVENT_ATTACH
      elsif current_state == STATE_UNATTACHED and last_state == STATE_ATTACHED
        event = EVENT_UNATTACH
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



  def has_published_schedules?(zones = [])
    if zones.blank?
      self.teacher_schedules.where('state IN (?) AND start_date >= ?', ::TeacherSchedule::STATE_PUBLISHED, Time.zone.now.to_date).count > 0
    else
=begin
      zones_centers_ids = []
      zones.each { |zone|
        zones_centers_ids += zone.center_ids
      }
      # if *any* of the center(s) specified in the teacher schedule, falls in the specified zone
      teacher_schedules = self.teacher_schedules.joins("JOIN centers_teacher_schedules ON teacher_schedules.id = centers_teacher_schedules.teacher_schedule_id").where('teacher_schedules.state IN (?) AND teacher_schedules.start_date >= ? AND centers_teacher_schedules.center_id IN (?)', ::TeacherSchedule::STATE_PUBLISHED, Time.zone.now.to_date, zones_centers_ids)
      # only if all the centers for the schedule fall in the zone
      count = 0
      teacher_schedules.each { |ts|
        count += 1 if (ts.center_ids - zones_centers_ids).blank?
      }
      return count
=end
    end
  end

  def delete_published_schedules(zones = [])
    if zones.blank?
      self.teacher_schedules.where('state IN (?) AND start_date >= ?', ::TeacherSchedule::STATE_PUBLISHED, Time.zone.now.to_date).delete_all
    else
=begin
      zones_centers_ids = []
      zones.each { |zone|
        zones_centers_ids += zone.center_ids
      }
      # if *any* of the center(s) specified in the teacher schedule, falls in the specified zone
      teacher_schedules = self.teacher_schedules.joins("JOIN centers_teacher_schedules ON teacher_schedules.id = centers_teacher_schedules.teacher_schedule_id").where('teacher_schedules.state IN (?) AND teacher_schedules.start_date >= ? AND centers_teacher_schedules.center_id IN (?)', ::TeacherSchedule::STATE_PUBLISHED, Time.zone.now.to_date, zones_centers_ids)
      # only if all the centers for the schedule fall in the zone
      teacher_schedules.each { |ts|
        unattached_center_ids = ts.center_ids - (ts.center_ids - zone_center_ids)
        if (unattached_centers == ts.center_ids)
          # delete teacher schedule if all centers belong to zone(s) which are getting unattached
          ts.destroy
        elsif not unattached_center_ids.blank?
          # else - delete the center_teacher_schedule mapping for center(s) getting unattached from the specific teacher schedule
          CenterTeacherSchedules.joins("JOIN teacher_schedules ON teacher_schedules.id = centers_teacher_schedules.teacher_schedule_id").where("centers_teacher_schedules.center_id IN (?) AND centers_teacher_schedules.teacher_schedule_id = ?", unattached_center_ids, ts.id).delete_all
        end
      }
=end
    end
  end

  def in_schedule?(zone)
    self.teacher_schedules.each { |ts|
      return true if ts.is_connected? and ts.program.center.zone == zone
    }
    return false
  end

  def has_centers?
    self.errors.add(:centers, " needed if teacher attached to zone(s).") if !self.zones.blank? && self.centers.blank? and (!self.full_time?)
    self.errors.add(:zones, " needed if teacher attached to center(s). To un-attach from a zone, first remove the center(s).") if self.zones.blank? && !self.centers.blank? and (!self.full_time?)
    #self.errors.add(:centers, " should belong to one sector.") if self.centers && !::Sector::all_centers_in_one_sector?(self.centers)
    self.centers.each { |center|
      unless self.zones.include?(center.zone)
        self.errors.add(:centers, " #{center.name} does not belong to specified zone(s).")
        break
      end
    }
    unless self.full_time?
      self.zones.each {|zone|
        if (self.center_ids - zone.center_ids) == self.center_ids
          self.errors.add(:zone, " #{zone.name} does not have any center specified.")
          break
        end
      }
    end
  end


  def has_program_types?
    no_of_program_types = self.role_program_types.inject(0){|a,(_,b)|a+b.size}
    self.errors.add(:program_types, "Teacher needs to be associated with program type(s) in at least one role.") unless no_of_program_types > 0
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
      return true if User.current_user.is? :zao, :for => :any, :center_id => self.center_ids
    else
      return true if User.current_user.is? :center_scheduler, :for => :any, :center_id => self.center_ids
    end
    return true if User.current_user.is? :teacher_training_department, :for => :any, :center_id => self.center_ids
    return true if self.is_current_user?
    return false
  end

  def can_view_schedule?
    if self.full_time?
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
    if self.center_ids.blank?
      center_ids = []
      self.zones.each { |zone|
        center_ids += zone.center_ids
      }
    else
      center_ids = self.center_ids
    end
    # only teacher training department can now update the teacher status
    return true if User.current_user.is? :teacher_training_department, :center_id => center_ids
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

  def can_be_blocked_by?(program, role)
    # check if teacher has matching program_type for the specified role
    return [] unless self.role_program_types(role).include?(program.program_donation.program_type)

    timing_ids = []
    # if given a program, we are trying to block a teacher
    if self.full_time?
      ts = TeacherSchedule.new
      ts.program = program
      ts.teacher_id = self.id
      # for each of the program timing_ids
      program.timing_ids.each { |timing_id|
        ts.timing_id = timing_id
        # if program schedule does not overlap any other schedule for the teacher
        timing_ids << timing_id unless ts.schedule_overlaps?
      }
    else
      # for each of the program timing_ids
      program.timing_ids.each { |timing_id|
        ts = self.teacher_schedules.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").where('teacher_schedules.start_date <= ? AND teacher_schedules.end_date >= ? AND teacher_schedules.timing_id = ? AND teacher_schedules.state = ? AND centers_teacher_schedules.center_id = ? ',
                                                                                                                                                        program.start_date.to_date, program.end_date.to_date, timing_id,
                                                                                                                                                        ::TeacherSchedule::STATE_AVAILABLE, program.center_id).first
        timing_ids << timing_id unless ts.nil?
      }
    end
    return timing_ids
  end

  def can_be_blocked_by_given_timings?(program, role, timing_ids)
    # check if teacher has matching program_type for the specified role
    return false unless self.role_program_types(role).include?(program.program_donation.program_type)

    # if given a program, we are trying to block a teacher
    if self.full_time?
      ts = TeacherSchedule.new
      ts.program = program
      ts.teacher_id = self.id
      # for each of the specified timing_ids
      timing_ids.each { |timing_id|
        ts.timing_id = timing_id
        # if program schedule does not overlap any other schedule for the teacher
        return false if ts.schedule_overlaps?
      }
    else
      ts = self.teacher_schedules.joins("JOIN centers_teacher_schedules ON centers_teacher_schedules.teacher_schedule_id = teacher_schedules.id").where('teacher_schedules.start_date <= ? AND teacher_schedules.end_date >= ? AND teacher_schedules.timing_id IN (?) AND teacher_schedules.state = ? AND centers_teacher_schedules.center_id = ? ',
                                                                                                                                                        program.start_date.to_date, program.end_date.to_date, timing_ids,
                                                                                                                                                        ::TeacherSchedule::STATE_AVAILABLE, program.center_id).first
      return false if ts.nil?
    end
    return true
  end

  def full_time?
    return self.full_time
  end

  def role_program_types(role = nil)
    if role.blank?
      program_types = {}
      ::Teacher::PROGRAM_TYPES.each { |k,v|
        program_types[k] = eval ("self." + v)
      }
      return program_types
    else
      return eval ("self." + ::Teacher::PROGRAM_TYPES[role])
    end
  end

  def roles
    roles = []
    self.role_program_types.each.each { |k, v|
      roles += [k] unless v.blank?
    }
    return roles
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
      #field :state
      field :program_types
      field :zones
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
      #field :part_time_co_teacher do
      #  label "(Part Time) Co-Teacher"
      #  help "If a part-time teacher can be scheduled as co-teacher for other programs."
      #  read_only do
      #    not ( bindings[:controller].current_user.is?(:super_admin) or bindings[:controller].current_user.is?(:teacher_training_department) )
      #  end
      #end
=begin
      field :state, :enum do
        label "Status"
        enum do
          # This is a HACK to represent some sort of state machine through rails_admin
          # if bindings[:object].state == STATE_UNATTACHED && (bindings[:controller].current_user.is? :super_admin, :center_id => bindings[:object].center_ids)
          #   [STATE_UNATTACHED, STATE_ATTACHED]
          # elsif bindings[:object].state == STATE_UNATTACHED && (bindings[:controller].current_user.is? :zao, :center_id => bindings[:object].center_ids)
          #   [STATE_UNATTACHED]
          # elsif bindings[:object].state == STATE_ATTACHED && (bindings[:controller].current_user.is? :zao, :center_id => bindings[:object].center_ids)
          #   [STATE_UNATTACHED, STATE_ATTACHED]
          # elsif (bindings[:controller].current_user.is? :teacher_training_department, :center_id => bindings[:object].center_ids)
          #   [STATE_UNATTACHED]
          # else
          #   []
          # end

          # Changed by Senthil based on discussion wiht Radha Akka. Currently displaying all the states and this can changed only by teacher training department.
          # This will be read only for all other users.
          [STATE_UNATTACHED, STATE_ATTACHED]
        end
        read_only do
          # user.is? is always returning true for super admin even if we a super admin is? :teacher_training_department,
          # but here we want to make this field read, only if use is super admin.
          if bindings[:controller].current_user.is?(:super_admin)
            # 7 Sep 2014 - Anuj - allowing super_admin same access as teacher_training_department
            false #true
          elsif bindings[:controller].current_user.is?(:teacher_training_department)
            false
          else
            true
          end
        end
      end
=end
      field :program_types  do
        label "Main Teacher"
        inverse_of :teachers
        #inline_edit false
        inline_add false
        read_only do
          # user.is? is always returning true for super admin even if we a super admin is? :teacher_training_department,
          # but here we want to make this field read, only if use is super admin.
          if bindings[:controller].current_user.is?(:super_admin)
            # 7 Sep 2014 - Anuj - allowing super_admin same access as teacher_training_department
            false #true
          elsif bindings[:controller].current_user.is?(:teacher_training_department)
            false
          else
            true
          end
        end
      end
      field :co_teacher_program_types  do
        label "Co-Teacher"
        inverse_of :teachers
        #inline_edit false
        inline_add false
        read_only do
          # user.is? is always returning true for super admin even if we a super admin is? :teacher_training_department,
          # but here we want to make this field read, only if use is super admin.
          if bindings[:controller].current_user.is?(:super_admin)
            # 7 Sep 2014 - Anuj - allowing super_admin same access as teacher_training_department
            false #true
          elsif bindings[:controller].current_user.is?(:teacher_training_department)
            false
          else
            true
          end
        end
      end
      field :organizing_teacher_program_types  do
        label "Organizing Teacher"
        inverse_of :teachers
        #inline_edit false
        inline_add false
        read_only do
          # user.is? is always returning true for super admin even if we a super admin is? :teacher_training_department,
          # but here we want to make this field read, only if use is super admin.
          if bindings[:controller].current_user.is?(:super_admin)
            # 7 Sep 2014 - Anuj - allowing super_admin same access as teacher_training_department
            false #true
          elsif bindings[:controller].current_user.is?(:teacher_training_department)
            false
          else
            true
          end
        end
      end
      field :hall_teacher_program_types  do
        label "Hall Teacher"
        inverse_of :teachers
        #inline_edit false
        inline_add false
        read_only do
          # user.is? is always returning true for super admin even if we a super admin is? :teacher_training_department,
          # but here we want to make this field read, only if use is super admin.
          if bindings[:controller].current_user.is?(:super_admin)
            # 7 Sep 2014 - Anuj - allowing super_admin same access as teacher_training_department
            false #true
          elsif bindings[:controller].current_user.is?(:teacher_training_department)
            false
          else
            true
          end
        end
      end
      field :initiation_teacher_program_types  do
        label "Initiation Teacher"
        inverse_of :teachers
        #inline_edit false
        inline_add false
        read_only do
          # user.is? is always returning true for super admin even if we a super admin is? :teacher_training_department,
          # but here we want to make this field read, only if use is super admin.
          if bindings[:controller].current_user.is?(:super_admin)
            # 7 Sep 2014 - Anuj - allowing super_admin same access as teacher_training_department
            false #true
          elsif bindings[:controller].current_user.is?(:teacher_training_department)
            false
          else
            true
          end
        end
      end
      field :zones  do
        # inverse_of :teachers
        #inline_edit false
        inline_add false
        read_only do
          # user.is? is always returning true for super admin even if we a super admin is? :teacher_training_department,
          # but here we want to make this field read, only if use is super admin.
          if bindings[:controller].current_user.is?(:super_admin)
            # 7 Sep 2014 - Anuj - allowing super_admin same access as teacher_training_department
            false #true
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
      field :comments do
        help "Optional. E.g, Feedback about the teacher (NOTE - field not visible to teacher)"
      end
      field :additional_comments do
        label "Note for Scheduler"
        help "Optional. Additional comments from/about teacher needed when scheduling (NOTE - field visible to part-time, but not full-time teacher)"
      end
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
