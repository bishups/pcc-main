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
  validates :language, :name, :presence => true
  validates :no_of_days, :length => { is: 1}, :numericality => {:only_integer => true }
  validates :minimum_no_of_teacher, :length => { is: 1}, :numericality => {:only_integer => true }


  rails_admin do
    navigation_label 'Access Privilege'
    weight 0
    list do
      field :name
      field :language
      field :no_of_days
      field :minimum_no_of_teacher
    end
    edit do
      field :name
      field :language do
      end
      field :no_of_days do
        label "Number of days"
      end
      field :minimum_no_of_teacher do
        label "Minimum number of teachers"
      end
    end
  end
end
