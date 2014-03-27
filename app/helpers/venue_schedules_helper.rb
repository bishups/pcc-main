module VenueSchedulesHelper
  
  def venue_schedule_state_tag(vs)
    proc do
      if vs.block_requested?
        '<span class="label label-info">Blocked Requested</span>'
      elsif vs.blocked?
        '<span class="label label-info">Blocked</span>'
      elsif vs.approval_requested?
        '<span class="label label-info">Approval Requested</span>'
      elsif vs.authorized_for_payment?
        '<span class="label label-info">Authorized for Payment</span>'
      elsif vs.payment_pending?
        '<span class="label label-warning">Payment Pending</span>'
      elsif vs.paid?
        '<span class="label label-success">Paid</span>'
      elsif vs.cancelled?
        '<span class="label label-danger">Cancelled</span>'
      else
        '<span class="label label-default">Unknown</span>'
      end
    end.call().html_safe
  end

end
