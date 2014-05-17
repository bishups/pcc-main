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
  validates :no_of_days, :presence => true, :length => {:within => 1..2}, :numericality => {:only_integer => true }
  validates :minimum_no_of_teacher, :presence => true, :length => { is: 1}, :numericality => {:only_integer => true }
  validates_uniqueness_of :name, :scope => :deleted_at

  has_many :program_donations
  attr_accessible :program_donations, :program_donation_ids

  has_and_belongs_to_many :timings
  attr_accessible :timing_ids, :timings

  has_and_belongs_to_many :centers
  attr_accessible :centers, :center_ids

  acts_as_paranoid

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
      field :timings
      field :program_donations
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
      field :timings do
        inline_add false
      end
      field :program_donations do
        inline_add false
      end
    end
  end
end
