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

require 'test_helper'

class KitItemMappingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
