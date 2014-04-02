class Teacher < ActiveRecord::Base
  has_and_belongs_to_many :centers
  attr_accessible :center_ids, :centers
  validate :has_centers?

  has_and_belongs_to_many :program_types
  attr_accessible :program_type_ids, :program_types, :is_attached
  validate :has_program_types?

  belongs_to :user
  attr_accessible :user_id

  belongs_to :zone
  attr_accessible :zone_id
  validate :has_zone?

  attr_accessible :t_no
  validates :t_no, :presence => true, :length => { :in => 1..9}
  validates :email, :uniqueness => true, :format => {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}


  def has_centers?
    self.errors.add(:centers, "Teacher needs to be associated to center(s).") if self.centers.blank?
    self.errors.add(:centers, " should belong to one sector.") if !::Sector::all_centers_in_one_sector?(self.centers)
  end


  def has_program_types?
    self.errors.add(:program_types, "Teacher needs to be associated to program type(s).") if self.program_types.blank?
  end

  def has_zone?
    self.errors.add(:zone, " to which teacher is attached - Required.") if !self.is_attached.blank?
  end

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
    end
  end

end
