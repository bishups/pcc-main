module VenueSchedulesHelper
  
  def venue_schedule_state_tag(vs)
    proc do
      if vs.state == ::VenueSchedule::STATE_BLOCK_REQUESTED
        '<span class="label label-info">Blocked Requested</span>'
      elsif vs.state == ::VenueSchedule::STATE_BLOCKED
        '<span class="label label-info">Blocked</span>'
      elsif vs.state == ::VenueSchedule::STATE_APPROVAL_REQUESTED
        '<span class="label label-info">Approval Requested</span>'
      elsif vs.state == ::VenueSchedule::STATE_AUTHORIZED_FOR_PAYMENT
        '<span class="label label-info">Authorized for Payment</span>'
      elsif vs.state == ::VenueSchedule::STATE_PAYMENT_PENDING
        '<span class="label label-warning">Payment Pending</span>'
      elsif vs.state == ::VenueSchedule::STATE_PAID
        '<span class="label label-success">Paid</span>'
      elsif vs.state == ::VenueSchedule::STATE_CANCELLED
        '<span class="label label-danger">Cancelled</span>'
      else
        '<span class="label label-default">Unknown</span>'
      end
    end.call().html_safe
  end

end
