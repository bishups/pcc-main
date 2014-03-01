# == Schema Information
#
# Table name: teacher_schedules
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  slot       :string(255)
#  start_date :datetime
#  end_date   :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TeacherSchedule < ActiveRecord::Base
  # attr_accessible :title, :body
end
