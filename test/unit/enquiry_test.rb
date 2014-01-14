# == Schema Information
#
# Table name: enquiries
#
#  id          :integer          not null, primary key
#  topic       :string(255)
#  name        :string(255)
#  email       :string(255)
#  phone       :string(255)
#  mobile      :string(255)
#  description :text
#  state       :string(255)
#  external_id :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'test_helper'

class EnquiryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
