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
  include CommonFunctions
  attr_accessible :language, :minimum_no_of_teacher, :minimum_no_of_co_teacher, :minimum_no_of_hall_teacher, :minimum_no_of_organizing_teacher, :minimum_no_of_initiation_teacher, :name, :no_of_days, :custom_session_duration, :registration_close_timeout, :session_duration
  attr_accessible :intro_duration, :length => {:within => 1..3}, :numericality => {:only_integer => true, :greater_than => 0}
  attr_accessible :full_day, :combined_day
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
  validates :session_duration, :presence => true, :length => {:within => 1..3}, :numericality => {:only_integer => true }, :unless => :custom_session_duration?
  validates_uniqueness_of :name, :scope => :deleted_at
  validate :residential_program, :unless => :custom_session_duration?
  validate :intro_full_combined_day, :unless => :custom_session_duration?
  validate :valid_custom_session_duration?
  validate :has_timings?

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

  def has_timings?
    if self.timings.blank?
      self.errors[:timings] << " cannot be left unselected. Select at least one timing."
      return
    end
  end

  def residential_program
    if self.session_duration.blank? or self.session_duration == 0
      self.errors[:session_duration] << " invalid."
      return
    end

    if not self.session_duration.blank? and self.session_duration < 0
      if self.timings.length != Timing.all.count
        self.errors[:timings] << " cannot be left unselected. Please select all timings for a residential program."
        return
      end
      if self.no_of_days < 2
        self.errors[:no_of_days] << " cannot be less than 2 for residential program."
        return
      end
    end
  end

  def intro_full_combined_day
    if self.intro_duration.blank? and self.full_day.blank? and self.combined_day.blank?
      return
    end

    if not self.session_duration.blank? and self.session_duration < 0
      if not self.intro_duration.blank?
        self.errors[:intro_duration] << " invalid."
        return
      end
      if not full_day.blank?
        self.errors[:full_day] << " invalid."
        return
      end
      if not combined_day.blank?
        self.errors[:combined_day] << " invalid."
        return
      end
    end

    if not self.full_day.blank? and not (self.full_days  - (1..self.no_of_days).to_a).blank?
      self.errors[:full_day] << " invalid. Please enter valid value between 1 and #{self.no_of_days}."
      return
    end
    if not self.combined_day.blank? and not (self.combined_days  - (1..self.no_of_days).to_a).blank?
      self.errors[:combined_day] << " invalid. Please enter valid value between 1 and #{self.no_of_days}."
      return
    end
    if not self.intro_duration.blank? and not self.full_day.blank? and self.full_days.include?(1)
      self.errors[:full_day] << " invalid. Day 1 cannot be marked as full day for program having first-day intro."
      return
    end
  end

  def full_days
    self.full_day.blank? ? [] : self.full_day.delete(' ').split(',').map {|c| c.to_i}
  end

  def has_full_day?
    not self.full_day.blank?
  end

  def combined_days
    self.combined_day.blank? ? [] : self.combined_day.delete(' ').split(',').map {|c| c.to_i}
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

  def custom_session_duration?
    not self.custom_session_duration.blank?
  end

  def has_intro?
    not self.intro_duration.blank?
  end

  #
  # E.g --
  #
  #   2 day program of total 9 hours, with two session of 3 hours on first day, and two sessions on second day (of 2 hours and 1 hours respectively)
  #   - no_of_days = 2
  #   - custom_session_duration = '3+3,2+1'
  #   NOTE - in this case multiple batches are not allowed
  #
  def valid_custom_session_duration?
    str = self.custom_session_duration
    return if str.blank?

    if not self.session_duration.blank?
      self.errors[:session_duration] << " invalid. Leave blank if custom session duration specified."
      return
    end

    if not self.intro_duration.blank?
      self.errors[:intro_duration] << " invalid."
      return
    end

    if not self.full_day.blank?
      self.errors[:full_day] << " invalid."
      return
    end

    if not self.combined_day.blank?
      self.errors[:combined_day] << " invalid."
      return
    end

    if self.timings.length != Timing.all.count
      self.errors[:timings] << " cannot be left unselected. Please select all timings for custom session duration."
      return
    end

    if not str.match(/^[0-9][0-9+., ]*[0-9]$/)
      self.errors[:custom_session_duration] << " invalid. Only numeric values allowed, separated by + or ,"
      return
    end

    if not (str.include?("+") or str.include?(","))
      self.errors[:custom_session_duration] << " invalid. Please specify numeric values separated by + or ,"
      return
    end

    days = str.delete(' ').split(',')
    if days.length != self.no_of_days
      self.errors[:custom_session_duration] << " invalid. Number of days do not match earlier specified value."
      return
    end

    days.each { |day|
      if not is_integer?(day[-1])
        self.errors[:custom_session_duration] << " invalid. Trailing special characters not allowed."
        return
      end
      if day.include?("+")
        elements = day.split("+")
        if elements.length > 4
          self.errors[:custom_session_duration] << " invalid. Maximum four sessions allowed in a day."
          return
        end
        elements.each { |element|
          if not is_numeric?(element)
            self.errors[:custom_session_duration] << " invalid. Specify day with multiples sessions as 'session_duration_in_hrs + session_duration_in_hrs ...' . E.g., 2+3+2"
            return
          end
        }
        number, interval = Timing::interval
        if elements.map{|x| x.to_f}.inject(:+) > (number * interval)
          self.errors[:custom_session_duration] << " invalid. Total session duration for a day cannot exceed #{(number * interval)} hrs."
          return
        end
      end
    }
  end

  #
  # Assumes that validate_custom_session_duration was success, does not perform fresh validations --
  #
  def session_duration_list
    return [] if self.custom_session_duration.blank?
    days = []
    self.custom_session_duration.delete(' ').split(',').each { |day|
      if day.include?("+")
        days << day.split("+").map{|s| s.to_f}
      else
        days << [day.to_f]
      end
    }
    return days
  end

  def session_offsets
    sessions = self.session_duration_list
    offsets = []
    offset = 0
    sessions.each { |day|
      if day.is_a? Array
        offsets += day.map{|d| offset}
      else
        offsets << offset
      end
      offset += 1
    }
    offsets
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
      field :session_duration do
        label "Duration of one session (in hrs)"
        help "Enter -1 for a residential program."
      end
      field :timings do
        inline_add false
      end
      field :program_donations do
        inline_add false
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
      field :intro_duration do
        label "Intro duration (in minutes)"
        help "e.g., 75 for IE. Leave blank for residential or hatha yoga programs."
      end
      field :full_day do
        label "Full Day(s)"
        help "e.g., 5 for IE. Leave blank for residential or hatha yoga programs. Comma separate multiple values (e.g., 3,4 for Sadhguru IE)"
      end
      field :combined_day do
        label "Combined Day(s)"
        help "Day(s) when combined session can happen for multiple programs (e.g., 5 for IE). Leave blank for residential or hatha yoga programs. Comma separate multiple values."
      end
      field :custom_session_duration do
        label "Custom Session Duration"
        help "Valid only for hatha yoga modules. E.g., 4+4,3 (for two four-hour, and one three-hour session. Two on first day, one on second day)"
      end
    end
  end
end
