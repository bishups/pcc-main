# == Schema Information
#
# Table name: program_types
#
#  id                    :integer          not null, primary key
#  name                  :string(255)
#  language              :string(255)
#  no_of_days            :integer
#  minimum_no_of_teacher :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

require 'test_helper'

class ProgramTypeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
