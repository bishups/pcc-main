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
  attr_accessible :name
end
