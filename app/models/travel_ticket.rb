class TravelTicket < ActiveRecord::Base
  mount_uploader :attachment, AttachmentUploader # Tells rails to use this uploader for this model.
  validates :name, presence: true # Make sure the owner's name is present.
  attr_accessible :attachment, :name
  belongs_to :pcc_travel_request, :class_name =>PccTravelRequest
  attr_accessible :upload_ticket,:pcc_travel_request_id

  def is_pcc_travel_vendor?
    if User.current_user.fullname=='Super admin ' || (User.current_user.is? :pcc_travel_vendor, :in_group => [:pcc_travel_vendor])
      return true
    else
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    end
  end
end
