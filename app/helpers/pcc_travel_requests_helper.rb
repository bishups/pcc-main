module PccTravelRequestsHelper
  def pcc_travel_request_state_tag(v)
    proc do
      case v.state
        when ::PccTravelRequest::STATE_PENDING
          '<span class="label label-info">Pending</span>'
        when ::PccTravelRequest::STATE_NEED_APPROVAL
          '<span class="label label-warning">Need Approval</span>'
        when ::PccTravelRequest::STATE_NEED_CLARIFICATION
          '<span class="label label-warning">Need Clarification</span>'
        when ::PccTravelRequest::STATE_BOOKED
          '<span class="label label-success">Booked</span>'
        when ::PccTravelRequest::STATE_REJECTED
          '<span class="label label-default">Rejected</span>'
        when ::PccTravelRequest::STATE_CANCELLED
          '<span class="label label-default">Cancelled</span>'
        when ::PccTravelRequest::STATE_APPROVED
          '<span class="label label-success">Approved</span>'
        when ::PccTravelRequest::STATE_CANCELLATION_REQUESTED
          '<span class="label label-warning">Cancellation Requested</span>'
        when ::PccTravelRequest::STATE_WITHDRAWN
          '<span class="label label-default">Withdrawn</span>'
        when ::PccTravelRequest::STATE_TICKET_UPLOADED
          '<span class="label label-success">Ticket Uploaded</span>'
        else
          '<span class="label label-default">Unknown</span>'
      end
    end.call().html_safe
  end
end
