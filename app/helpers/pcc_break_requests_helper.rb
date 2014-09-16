module PccBreakRequestsHelper
  def pcc_break_request_state_tag(v)
    proc do
      case v.state
        when ::PccBreakRequest::STATE_PENDING
          '<span class="label label-info">Pending</span>'

        when ::PccBreakRequest::STATE_NEED_CLARIFICATION
          '<span class="label label-warning">Need Clarification</span>'

        when ::PccBreakRequest::STATE_REJECTED
          '<span class="label label-default">Rejected</span>'
        when ::PccBreakRequest::STATE_CANCELLED
          '<span class="label label-default">Cancelled</span>'
        when ::PccBreakRequest::STATE_APPROVED
          '<span class="label label-success">Approved</span>'

        else
          '<span class="label label-default">Unknown</span>'
      end
    end.call().html_safe
  end
end