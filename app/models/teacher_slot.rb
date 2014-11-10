# == Schema Information
#
# Table name: teacher_slots
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  status     :string(255)
#  slot       :string(255)
#  date       :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TeacherSlot < ActiveRecord::Base
  attr_accessible :date, :slot, :status

  belongs_to :user

  validates :date, :presence => true
  validates :slot, :presence => true
  validates :status, :presence => true
  validates :user_id, :presence => true

#  validate :start_and_end_dates, :scheduleOverlapNotAllowed

  # Validator
  def start_and_end_dates
    if self.date
      errors.add(:date, "- Start date must be in the future") if self.date < Time.zone.now
    end
  end

end
