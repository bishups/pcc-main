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

require 'test_helper'

class KitItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
