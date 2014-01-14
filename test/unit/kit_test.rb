# == Schema Information
#
# Table name: kits
#
#  id                     :integer          not null, primary key
#  state                  :string(255)
#  max_participant_number :integer
#  filling_person_id      :integer
#  center_id              :integer
#  guardian_id            :integer
#  issued_to_person_id    :integer
#  blocked_by_person_id   :integer
#  assigned_to_program_id :integer
#  condition              :string(255)
#  condition_comments     :text
#  general_comments       :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

require 'test_helper'

class KitTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
