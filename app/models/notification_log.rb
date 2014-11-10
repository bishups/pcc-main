# == Schema Information
#
# Table name: notification_logs
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  date       :datetime
#  model_id   :integer
#  model_type :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  text1      :string(255)
#  text2      :string(255)
#  displayed  :boolean          default(FALSE)
#  disabled   :boolean          default(FALSE)
#

class NotificationLog < ActiveRecord::Base
  belongs_to :user
  belongs_to :model, :polymorphic => true
  attr_accessible :user, :model_id, :model_type, :date, :text1, :text2, :displayed
  validates :user, :model_id, :model_type, :date, :text1, :text2, :presence => true

  def model_state_tag
    "#{model_type.underscore}_state_tag"
  end

  def object
    if model_type == "ProgramTeacherSchedule"
      TeacherSchedule.find(model_id)
    else
      model_type.constantize.find(model_id)
    end
  rescue ActiveRecord::RecordNotFound => e
    nil
  end

  def displayed!
    self.update_attribute(:displayed, true) unless self.displayed == true
  end

  # this is a cron job, run through whenever gem
  # from the config/schedule.rb file
  def self.delete_old_logs
    NotificationLog.where('date < ?', (Time.zone.now - 1.month.from_now)).delete_all
  end


end
