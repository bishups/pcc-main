class ActivityLog < ActiveRecord::Base
  belongs_to :user
  belongs_to :model, :polymorphic => true
  attr_accessible :user, :model_id, :model_type, :date, :text, :presence
  validates :user, :model_id, :model_type, :date, :text, :presence => true
end
