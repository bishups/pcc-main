class NotificationLog < ActiveRecord::Base
  belongs_to :user
  belongs_to :model, :polymorphic => true
  attr_accessible :user, :model_id, :model_type, :date, :text1, :text2, :presence
  validates :user, :model_id, :model_type, :date, :text1, :text2, :presence => true

  def model_state_tag
    "#{model_type.underscore}_state_tag"
  end

  def object
    model_type.constantize.find(model_id)
  rescue ActiveRecord::RecordNotFound => e
    nil
  end


end
