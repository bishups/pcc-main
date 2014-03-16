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
  has_many :centers, :through => :sectors
  has_many :access_privileges, :as => :resource, :inverse_of => :resource

  validates :name, :presence => true

  attr_accessible :name, :sector_ids, :sectors

  rails_admin do
    navigation_label 'Geo-graphical informations'
      weight 0
    list do
      field :name
      field :sectors
    end
    edit do
      field :name
      field :sectors   do
        inline_add do
          false
        end
      end
    end
  end

end
