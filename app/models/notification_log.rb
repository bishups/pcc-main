class NotificationLog < ActiveRecord::Base
  belongs_to :user
  belongs_to :model, :polymorphic => true
  attr_accessible :user, :model_id, :model_type, :date, :log, :presence
  validates :user, :model_id, :model_type, :date, :log, :presence => true
end
