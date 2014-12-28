# == Schema Information
#
# Table name: program_types
#
#  id                               :integer          not null, primary key
#  name                             :string(255)
#  language                         :string(255)
#  no_of_days                       :integer
#  minimum_no_of_teacher            :integer
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  deleted_at                       :datetime
#  registration_close_timeout       :integer
#  minimum_no_of_co_teacher         :integer
#  sync_ts                          :string(255)
#  sync_id                          :string(255)
#  session_duration                 :integer
#  minimum_no_of_organizing_teacher :integer          default(-1)
#  minimum_no_of_hall_teacher       :integer          default(-1)
#  minimum_no_of_initiation_teacher :integer          default(-1)
#

class ProgramType < ActiveRecord::Base
  attr_accessible :language, :minimum_no_of_teacher, :minimum_no_of_co_teacher, :minimum_no_of_hall_teacher, :minimum_no_of_organizing_teacher, :minimum_no_of_initiation_teacher, :name, :no_of_days, :registration_close_timeout, :session_duration
  attr_accessible :intro_day, :initiation_day, :length => {:within => 1..2}, :numericality => {:only_integer => true, :greater_than => 0}
  attr_accessible :intro_duration, :length => {:within => 1..3}, :numericality => {:only_integer => true, :greater_than => 0}
  has_and_belongs_to_many :teachers
  has_and_belongs_to_many :co_teacher_program_types, class_name: "Teacher", join_table: "program_types_co_teachers"
  has_and_belongs_to_many :organizing_teacher_program_types, class_name: "Teacher", join_table: "program_types_organizing_teachers"
  has_and_belongs_to_many :hall_teacher_program_types, class_name: "Teacher", join_table: "program_types_hall_teachers"
  has_and_belongs_to_many :initiation_teacher_program_types, class_name: "Teacher", join_table: "program_types_initiation_teachers"
  validates :language, :name, :presence => true
  validates :no_of_days, :presence => true, :length => {:within => 1..2}, :numericality => {:only_integer => true }
  validates :minimum_no_of_teacher, :presence => true, :length => {:within => 1..2}, :numericality => {:only_integer => true, :greater_than => 0 }
  validates :minimum_no_of_co_teacher, :presence => true, :length => {:within => 1..2}, :numericality => {:only_integer => true }
  validates :minimum_no_of_organizing_teacher, :presence => true, :length => {:within => 1..2}, :numericality => {:only_integer => true }
  validates :minimum_no_of_hall_teacher, :presence => true, :length => {:within => 1..2}, :numericality => {:only_integer => true }
  validates :minimum_no_of_initiation_teacher, :presence => true, :length => {:within => 1..2}, :numericality => {:only_integer => true }
  validates :registration_close_timeout, :presence => true, :length => {:within => 1..3}, :numericality => {:only_integer => true }
  validates :session_duration, :presence => true, :length => {:within => 1..3}, :numericality => {:only_integer => true }
  validates_uniqueness_of :name, :scope => :deleted_at
  validate :residential_program
  validate :intro_initiation_day

  MIN_NO_TEACHER = {
      ::TeacherSchedule::ROLE_MAIN_TEACHER => "minimum_no_of_teacher" ,
      ::TeacherSchedule::ROLE_CO_TEACHER => "minimum_no_of_co_teacher",
      ::TeacherSchedule::ROLE_ORGANIZING_TEACHER => "minimum_no_of_organizing_teacher",
      ::TeacherSchedule::ROLE_HALL_TEACHER => "minimum_no_of_hall_teacher",
      ::TeacherSchedule::ROLE_INITIATION_TEACHER => "minimum_no_of_initiation_teacher"
  }

  has_many :program_donations
  attr_accessible :program_donations, :program_donation_ids

  has_and_belongs_to_many :timings
  attr_accessible :timing_ids, :timings

  has_and_belongs_to_many :centers
  attr_accessible :centers, :center_ids

  acts_as_paranoid

  def residential_program
    if self.session_duration == 0
      self.errors[:session_duration] << " invalid. Please specify value > 0. For residential specify -1."
      return
    end

    if self.session_duration < 0
      if self.timings.count != Timing.all.count
        self.errors[:timings] << " cannot be left unselected. Please select all timings for a residential program."
        return
      end
      if self.no_of_days < 2
        self.errors[:no_of_days] << " cannot be less than 2 for residential program."
        return
      end
    end
  end

  def intro_initiation_day
    if self.intro_day.blank? and self.initiation_day.blank?
      return
    end

    if self.session_duration < 0
      if not intro_day.blank?
        self.errors[:intro_day] << " invalid. Please leave blank for residential programs."
        return
      end
      if not initiation_day.blank?
        self.errors[:initiation_day] << " invalid. Please leave blank for residential programs."
        return
      end
    end

    if not self.intro_day.blank? and (self.intro_day > self.no_of_days )
      self.errors[:intro_day] << " invalid. Please enter valid integer between 1 and #{self.no_of_days}."
      return
    end
    if self.intro_day.blank? and not self.intro_duration.blank?
      self.errors[:intro_day] << " required if intro duration is specified. Please enter valid for intro day, or remove intro duration."
      return
    end
    if not self.intro_day.blank? and self.intro_duration.blank?
      self.errors[:intro_duration] << " required if intro day is specified. Please enter valid for intro duration, or remove intro day."
      return
    end
    if not self.initiation_day.blank? and (self.initiation_day > self.no_of_days)
      self.errors[:initiation_day] << " invalid. Please enter valid integer between 1 and #{self.no_of_days}."
      return
    end
    # if same day specified in both
    if self.intro_day ==  self.initiation_day
      self.errors[:initiation_day] << " invalid. Same day marked as both intro day and initiation day."
    end
  end

  def role_minimum_no_of_teacher(role = nil)
    if role.blank?
      minimum_no_of_teacher = {}
      ::ProgramType::MIN_NO_TEACHER.each { |k,v|
        minimum_no_of_teacher[k] = eval ("self." + v)
      }
      return minimum_no_of_teacher
    else
      return eval ("self." + ::ProgramType::MIN_NO_TEACHER[role])
    end
  end

  def roles
    roles = []
    self.role_minimum_no_of_teacher.each { |k,v|
      roles += [k] unless v == -1
    }
    return roles
  end

  def residential?
    self.session_duration.blank? ? false : self.session_duration < 0
  end

  def has_intro?
    self.intro_day.blank? ? false : true
  end

  rails_admin do
    navigation_label 'Program'
    weight 0
    visible do
      bindings[:controller].current_user.is?(:super_admin)
    end
    list do
      field :name
      field :language
      field :no_of_days
      field :minimum_no_of_teacher
      field :minimum_no_of_co_teacher
      field :timings
      field :program_donations
      field :registration_close_timeout
    end
    edit do
      field :name
      field :language do
      end
      field :no_of_days do
        label "Number of days"
      end
      field :minimum_no_of_teacher do
        label "Minimum number of Main Teachers"
      end
      field :minimum_no_of_co_teacher do
        label "Minimum number of Co-Teachers"
        help "Enter -1 if not applicable, 0 if optional."
      end
      field :minimum_no_of_organizing_teacher do
        label "Minimum number of Organizing Teachers"
        help "Enter -1 if not applicable, 0 if optional."
      end
      field :minimum_no_of_hall_teacher do
        label "Minimum number of Hall Teachers"
        help "Enter -1 if not applicable, 0 if optional."
      end
      field :minimum_no_of_initiation_teacher do
        label "Minimum number of Initiation Teachers"
        help "Enter -1 if not applicable, 0 if optional."
      end
      field :registration_close_timeout do
        label "Registration Close Timeout (in hrs)"
        help "(If not already closed) the number of hours (after start of program), when registration is marked closed. Negative values are allowed."
      end
      field :session_duration do
        label "Duration of one session (in hrs)"
        help "Enter -1 for a residential program"
      end
      field :timings do
        inline_add false
      end
      field :intro_day do
        label "Intro day"
        help "e.g., 1 for IE. Not valid for residential programs."
      end
      field :intro_duration do
        label "Intro duration (in minutes)"
        help "e.g., 75 for IE. Required, if intro day is specified."
      end
      field :initiation_day do
        label "Initiation day"
        help "e.g., 5 for IE. Not valid for residential programs."
      end
      field :program_donations do
        inline_add false
      end
    end
  end
end
