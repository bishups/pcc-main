# == Schema Information
#
# Table name: kit_item_mappings
#
#  id          :integer          not null, primary key
#  kit_id      :integer
#  kit_item_id :integer
#  count       :integer
#  condition   :string(255)
#  comments    :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class KitItemMapping < ActiveRecord::Base
  belongs_to :kit
  belongs_to :kit_item

  attr_accessible :kit_item_id, :kit_id, :count, :capacity, :condition, :comments

end
