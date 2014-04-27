module VenuesHelper
  def venue_state_tag(v)
    proc do
      # TODO - change this once state machine is added to teacher schedule
      case v.state
        when ::Venue::STATE_PROPOSED
          '<span class="label label-info">Proposed</span>'
        when ::Venue::STATE_APPROVED
          '<span class="label label-warning">Approved</span>'
        when ::Venue::STATE_PENDING_FINANCE_APPROVAL
          '<span class="label label-info">Pending Finance Approval</span>'
        when ::Venue::STATE_INSUFFICIENT_INFO
          '<span class="label label-warning">Insufficient Info</span>'
        when ::Venue::STATE_REJECTED
          '<span class="label label-danger">Rejected</span>'
        when ::Venue::STATE_POSSIBLE
          '<span class="label label-success">Possible</span>'
        else
          '<span class="label label-default">Unknown</span>'
      end
    end.call().html_safe
  end
end

