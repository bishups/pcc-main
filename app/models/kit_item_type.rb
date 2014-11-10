# == Schema Information
#
# Table name: kit_item_types
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime
#

class KitItemType < ActiveRecord::Base
  attr_accessible :name, :description
  acts_as_paranoid

  validates :name, :presence => true
  rails_admin do
    navigation_label 'Kit Management'
    weight 2
    list do
      field :name
      field :description
    end
    edit do
      field :name
      field :description
    end
  end
end
