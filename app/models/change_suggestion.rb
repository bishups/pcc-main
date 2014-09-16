class ChangeSuggestion < ActiveRecord::Base
  attr_accessible :description, :done, :pcc_communication_request_id, :priority
  belongs_to :pcc_communication_request , :class_name=> PccCommunicationRequest
end
