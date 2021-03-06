module VenueSchedulesHelper
  
  def venue_schedule_state_tag(vs)
    proc do
      if vs.state == ::VenueSchedule::STATE_BLOCK_REQUESTED
        '<span class="label label-info">Block Requested</span>'
      elsif vs.state == ::VenueSchedule::STATE_BLOCKED
        '<span class="label label-info">Blocked</span>'
      elsif vs.state == ::VenueSchedule::STATE_UNAVAILABLE
        '<span class="label label-default">Unavailable</span>'
      elsif vs.state == ::VenueSchedule::STATE_APPROVAL_REQUESTED
        '<span class="label label-info">Approval Requested</span>'
      elsif vs.state == ::VenueSchedule::STATE_AUTHORIZED_FOR_PAYMENT
        '<span class="label label-info">Authorized for Payment</span>'
      elsif vs.state == ::VenueSchedule::STATE_PAYMENT_PENDING
        '<span class="label label-warning">Payment Pending</span>'
      elsif vs.state == ::VenueSchedule::STATE_PAID
        '<span class="label label-success">Paid</span>'
      elsif vs.state == ::VenueSchedule::STATE_ASSIGNED
        '<span class="label label-success">Assigned</span>'
      elsif vs.state == ::VenueSchedule::STATE_IN_PROGRESS
        '<span class="label label-warning">In Progress</span>'
      elsif vs.state == ::VenueSchedule::STATE_CONDUCTED
        '<span class="label label-info">Conducted</span>'
      elsif vs.state == ::VenueSchedule::STATE_CLOSED
        '<span class="label label-default">Closed</span>'
      elsif vs.state == ::VenueSchedule::STATE_CANCELLED
        '<span class="label label-danger">Cancelled</span>'
      elsif vs.state == ::VenueSchedule::STATE_SECURITY_REFUNDED
        '<span class="label label-warning">Security Refunded</span>'
      elsif prog.state == ::VenueSchedule::STATE_EXPIRED
        '<span class="label label-warning">Expired</span>'
      elsif prog.state == ::VenueSchedule::STATE_AVAILABLE_EXPIRED
        '<span class="label label-warning">Available (Expired)</span>'
      else
        '<span class="label label-default">Unknown</span>'
      end
    end.call().html_safe
  end
end
