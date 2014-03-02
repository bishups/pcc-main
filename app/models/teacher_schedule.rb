class TeacherSchedule < ActiveRecord::Base
  # attr_accessible :title, :body
  attr_accessible :start_date, :end_date, :slot

  belongs_to :user

  validates :start_date, :presence => true
  validates :end_date, :presence => true
  validates :slot, :presence => true
  validates :user_id, :presence => true

  validates :start_date, :end_date, :overlap => {:scope => ['user_id', 'slot'] }

  #validates_with TeacherScheduleValidator

  def teacher
    self.user
  end
end
