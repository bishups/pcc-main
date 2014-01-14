# == Schema Information
#
# Table name: kit_items
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  description   :text
#  kit_item_type :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class KitItem < ActiveRecord::Base
  attr_accessible :name, :description

  has_many :kit_item_mappings
  has_many :kits, :through => :kit_item_mappings
end
