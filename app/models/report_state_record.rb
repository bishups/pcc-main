# == Schema Information
#
# Table name: report_state_records
#
#  id          :integer          not null, primary key
#  record_name :string(255)
#  record_id   :integer
#  state       :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class ReportStateRecord < ActiveRecord::Base
  # attr_accessible :title, :body
end
