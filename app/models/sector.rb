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
  belongs_to :zone, :inverse_of => :sectors
  has_many :centers
  validates :name, :presence => true

  has_many :access_privileges, :as => :resource, :inverse_of => :resource


  attr_accessible :name, :zone_id, :center_ids
end
