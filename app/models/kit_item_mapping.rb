# == Schema Information
#
# Table name: kit_item_mappings
#
#  id          :integer          not null, primary key
#  kit_id      :integer
#  kit_item_id :integer
#  count       :integer
#  capacity    :string(255)
#  condition   :string(255)
#  comments    :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class KitItemMapping < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :kit
  belongs_to :kit_item
end
