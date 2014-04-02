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
  has_many :pincodes
  has_one :zone, :through => :sector
  has_many :access_privileges, :as => :resource, :inverse_of => :resource
  has_and_belongs_to_many :teachers
  has_and_belongs_to_many :kits
  has_and_belongs_to_many :venues
  attr_accessible :name, :sector_id, :sector, :pincodes, :pincode_ids

  validates :name,:sector, :presence => true



  rails_admin do
    navigation_label 'Geo-graphical informations'
    weight 2
    list do
      field :name
      field :sector
      field :zone
      field :pincodes
    end
    edit do
      field :name
      field :sector do
        inline_edit false
        inline_add false
      end
      field :pincodes do
        inline_add do
          false
        end
      end
    end
  end

end
