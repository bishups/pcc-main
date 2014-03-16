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
  validates :name,:zone, :presence => true

  has_many :access_privileges, :as => :resource, :inverse_of => :resource

  attr_accessible :name, :zone_id, :center_ids, :centers, :zone

  rails_admin do
    navigation_label 'Geo-graphical informations'
    weight 1
    list do
      field :name
      field :zone
    end
    edit do
      field :name
      field :zone  do
        inverse_of  :sectors
        inline_edit do
          false
        end
        inline_add do
          false
        end
      end
      field :centers do
        inline_add do
          false
        end
      end
    end
  end

end
