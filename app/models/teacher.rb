class Teacher < ActiveRecord::Base
  has_and_belongs_to_many :centers
  attr_accessible :center_ids, :centers
  validate :has_centers?

  has_and_belongs_to_many :program_types
  attr_accessible :program_type_ids, :program_types
  validate :has_program_types?

  belongs_to :user
  attr_accessible :user_id, :user

  belongs_to :zone
  attr_accessible :zone_id, :zone
  validate :has_zone?

  attr_accessible :t_no
  validates :t_no, :presence => true, :length => { :in => 1..9}
  #validates :email, :uniqueness => true, :format => {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}

  has_many :teacher_schedules
  attr_accessible :teacher_schedules, :teacher_schedule_ids

  attr_accessible :comments
  validate :has_comments?

  attr_accessible :state
  validates :state, :presence => true

  STATE_UNFIT  = :unfit
  STATE_UNATTACHED  = :unattached
  STATE_ATTACHED  = :attached

  PROCESSABLE_EVENTS = [
      :attach, :unattach, :unfit
  ]

  state_machine :state, :initial => STATE_UNATTACHED do
    event :attach do
      transition [STATE_UNATTACHED] => STATE_ATTACHED
    end

    event :unattach do
      # TODO - if not transitioning in state machine, see if need to pass back some error message
      transition [STATE_ATTACHED, STATE_UNFIT] => STATE_UNATTACHED, :if => lambda {|teacher| !teacher.in_schedule?}
    end
    after_transition :any => STATE_UNATTACHED, :do => :on_unattach

    event :unfit do
      transition [STATE_ATTACHED, STATE_UNATTACHED] => STATE_UNFIT, :if  => lambda {|teacher| !teacher.in_schedule?}
    end
    after_transition :any => STATE_UNATTACHED, :do => :on_unfit

  end

  def on_unattach
    self.zone = ""
  end

  def on_unfit
  end


  def clear_schedules
    self.teacher_schedules.each { |ts|
      ts.delete
    }
  end

  def in_schedule?
    in_schedule = false
    self.teacher_schedules.each { |ts|
      if !(ts.state == ::Ontology::Teacher::STATE_AVAILABLE.to_s || ts.state == ::Ontology::Teacher::STATE_UNAVAILABLE.to_s)
        in_schedule = true
        break
      end
    }
    in_schedule
  end


  def has_comments?
    self.errors.add(:comments, " needed if the teacher is marked unfit.") if (self.state == STATE_UNFIT.to_s) && self.comments.blank?
  end

  def has_centers?
    self.errors.add(:centers, " needed if teacher attached to a zone.") if !self.zone.blank? && self.centers.blank?
    self.errors.add(:zone, " needed if teacher attached to center(s). To un-attach from a zone, first remove the center(s).") if self.zone.blank? && !self.centers.blank?
    self.errors.add(:centers, " should belong to one sector.") if !::Sector::all_centers_in_one_sector?(self.centers)
    self.errors.add(:centers, " should belong to specified zone.") if self.centers && self.zone && self.centers[0].sector.zone != self.zone
  end


  def has_program_types?
    self.errors.add(:program_types, "Teacher needs to be associated to program type(s).") if self.program_types.blank?
  end

  def has_zone?
    self.errors.add(:zone, " cannot be blank when teacher is attached.") if self.zone.blank? && (self.state == STATE_ATTACHED.to_s)
    self.errors.add(:zone, " cannot be marked blank when teacher is in schedule.") if self.zone.blank? && self.in_schedule?
    self.errors.add(:zone, " need to be blank when teacher is marked unattached.") if !self.zone.blank? && (self.state == STATE_UNATTACHED.to_s)
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
          [STATE_UNFIT.to_s, STATE_UNATTACHED.to_s, STATE_ATTACHED.to_s]
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

end
