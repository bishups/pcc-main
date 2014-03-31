# == Schema Information
#
# Table name: program_types
#
#  id                    :integer          not null, primary key
#  name                  :string(255)
#  language              :string(255)
#  no_of_days            :integer
#  minimum_no_of_teacher :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class ProgramType < ActiveRecord::Base
  attr_accessible :language, :minimum_no_of_teacher, :name, :no_of_days
  has_and_belongs_to_many :teachers
  validates :language, :minimum_no_of_teacher, :name, :no_of_days, :presence => true
  validates :minimum_no_of_teacher, :no_of_days, :numericality => true
  validates_length_of :minimum_no_of_teacher, :no_of_days, :is => 1
end
