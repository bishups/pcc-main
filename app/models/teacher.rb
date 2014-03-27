class Teacher < User
  attr_accessible :isha_teacher_id
  has_and_belongs_to_many :centers
  has_and_belongs_to_many :program_types
end