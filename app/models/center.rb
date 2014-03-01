# == Schema Information
#
# Table name: centers
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  sector_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Center < ActiveRecord::Base
  belongs_to :sector
  has_many :access_privileges, :as => :resource, :inverse_of => :resource
  attr_accessible :name, :sector_id

  validates :name, :presence => true


end
