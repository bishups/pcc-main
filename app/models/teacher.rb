class Teacher < ActiveRecord::Base

  attr_accessor :current_user

  has_and_belongs_to_many :centers, :after_add => :add_access_privilege, :after_remove  => :remove_access_privilege
  attr_accessible :center_ids, :centers
  validate :has_centers?

  has_and_belongs_to_many :program_types
  attr_accessible :program_type_ids, :program_types
  validate :has_program_types?

  belongs_to :user
  attr_accessible :user_id, :user
  validates :user_id, :uniqueness => true

  belongs_to :zone
  attr_accessible :zone_id, :zone
  validate :has_zone?

  attr_accessible :t_no
  validates :t_no, :presence => true, :length => { :in => 1..9}
  #validates :email, :uniqueness => true, :format => {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}

  has_many :teacher_schedules
  has_many :timings, through: :teacher_schedules
  attr_accessible :teacher_schedules, :teacher_schedule_ids

  attr_accessible :comments
  validate :has_comments?

  attr_accessible :state
  validates :state, :presence => true
  validate :invalid_state?

  STATE_UNFIT       = 'Not Fit'
  STATE_UNATTACHED  = 'Not Attached'
  STATE_ATTACHED    = 'Attached'

  # The attach functionality need to be exercised through the admin interface only,
  # since zone(s) and center(s) need to be linked again
  # EVENT_ATTACH      = 'Attach '

  EVENT_UNATTACH    = 'Unattach from Zone'
  EVENT_UNFIT       = 'Mark as UnFit'

  PROCESSABLE_EVENTS = [
      EVENT_UNATTACH, EVENT_UNFIT
  ]

  state_machine :state, :initial => STATE_UNATTACHED do

    event EVENT_UNATTACH do
      # TODO - if not transitioning in state machine, see if need to pass back some error message
      transition [STATE_ATTACHED, STATE_UNFIT] => STATE_UNATTACHED #, :if => lambda {|teacher| !teacher.in_schedule?}
    end
    before_transition any => STATE_UNATTACHED, :do => :before_unattach
    after_transition any => STATE_UNATTACHED, :do => :after_unattach

    event EVENT_UNFIT do
      transition [STATE_ATTACHED] => STATE_UNFIT #, :if  => lambda {|teacher| !teacher.in_schedule?}
    end
    #before_transition any => STATE_UNFIT, :do => :before_mark_unfit
    after_transition any => STATE_UNFIT, :do => :after_unfit

  end

  def is_connected?(program)

    ::ProgramTeacherSchedule::CONNECTED_STATES.include?(self.state)
  end

  def before_unattach
    if self.in_schedule?
      self.errors.add(:state, " cannot unattach from zone when teacher is linked to a program.")
      return false
    end
    if self.comments.blank?
      self.errors.add(:comments, " needed if the teacher is marked unattached.")
      return false
    end

    self.zone_id = nil
    # Also remove all attached centers
    CentersTeachers.where(:teacher_id => self.id).delete_all
    # FIXME - deleting the centers here can be an issue if the transaction fails ...
  end

  def after_unattach
    # if marked unfit remove all teacher_schedules
    TeacherSchedule.where(:teacher_id => self.id).delete_all
  end

  def after_unfit
    # if marked unfit remove all teacher_schedules
    TeacherSchedule.where(:teacher_id => self.id).delete_all

    # Also remove all attached centers
    CentersTeachers.where(:teacher_id => self.id).delete_all
  end


  def in_schedule?
    in_schedule = false
    self.teacher_schedules.each { |ts|
      if !(::TeacherSchedule::STATE_PUBLISHED).include?(ts.state)
        in_schedule = true
        break
      end
    }
    in_schedule
  end


  def has_comments?
    self.errors.add(:comments, " needed if the teacher is marked unfit.") if (self.state == STATE_UNFIT) && self.comments.blank?
  end

  def has_centers?
    self.errors.add(:centers, " needed if teacher attached to a zone.") if !self.zone.blank? && self.centers.blank?
    self.errors.add(:zone, " needed if teacher attached to center(s). To un-attach from a zone, first remove the center(s).") if self.zone.blank? && !self.centers.blank?
    self.errors.add(:centers, " should belong to one sector.") if !::Sector::all_centers_in_one_sector?(self.centers)
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
      end
      field :t_no
      field :state, :enum do
        label "Status"
        # TODO - humanize the strings below, without breaking the state_machine functionality
        enum do
          [STATE_UNFIT, STATE_UNATTACHED, STATE_ATTACHED]
        end
      end
      field :zone  do
        inverse_of :teachers
        inline_edit false
        inline_add false
      end
      field :program_types  do
        inverse_of :teachers
        #inline_edit false
        inline_add false
      end
      field :centers do
        inverse_of  :teachers
        #inline_edit false
        inline_add false
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
