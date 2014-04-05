class Teacher < ActiveRecord::Base
  has_and_belongs_to_many :centers
  attr_accessible :center_ids, :centers
  validate :has_centers?

  has_and_belongs_to_many :program_types
  attr_accessible :program_type_ids, :program_types, :is_attached
  validate :has_program_types?

  belongs_to :user
  attr_accessible :user_id, :user

  belongs_to :zone
  attr_accessible :zone_id, :zone

  attr_accessible :t_no
  validates :t_no, :presence => true, :length => { :in => 1..9}
  #validates :email, :uniqueness => true, :format => {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}

  has_many :teacher_schedules
  attr_accessible :teacher_schedules, :teacher_schedule_ids

  attr_accessible :unfit, :comments
  validate :has_comments?

  def has_comments?
    self.errors.add(:comments, " needed if the teacher is marked unfit.") if !self.unfit.blank? && self.comments.blank?
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
    # self.errors.add(:zone, " to which teacher is attached - Required.") if !self.is_attached.blank?
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
      field :unfit
      field :comments
    end
  end

end
