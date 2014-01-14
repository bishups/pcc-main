# == Schema Information
#
# Table name: zones
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Zone < ActiveRecord::Base
  has_many :sectors
  attr_accessible :name, :sectors_attributes
  accepts_nested_attributes_for :sectors
end
