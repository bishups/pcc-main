# == Schema Information
#
# Table name: sectors
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  zone_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Sector < ActiveRecord::Base
  belongs_to :zone
  has_many :centers
  attr_accessible :name, :centers_attributes
  accepts_nested_attributes_for :centers
end
