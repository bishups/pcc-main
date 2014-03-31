class Teacher < ActiveRecord::Base
  has_and_belongs_to_many :centers
  attr_accessible :center_ids, :centers
  validate :has_centers?

  has_and_belongs_to_many :program_types
  attr_accessible :program_type_ids, :program_types
  validate :has_program_types?

  belongs_to :user
  attr_accessible :user_id

  belongs_to :zone
  attr_accessible :zone_id

  attr_accessible :t_no
  validates :t_no, :presence => true


  def has_centers?
    self.errors.add_to_base "Teacher needs to be associated to center(s)." if self.centers.blank?
  end


  def has_program_types?
    self.errors.add_to_base "Teacher needs to be associated to program type(s)." if self.program_types.blank?
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
