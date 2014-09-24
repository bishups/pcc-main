class PccCommunicationRequest < ActiveRecord::Base
  attr_accessible :attachment, :last_update, :last_updated_at, :last_updated_by_user_id, :purpose, :requester_id, :state, :target_audience, :deadline, :geography, :urgency, :other_geography, :other_target_audience
  mount_uploader :attachment, AttachmentUploader
  belongs_to :requester, :class_name => User
  belongs_to :last_updated_by_user ,:class_name => User
  has_many :change_suggestions
end
