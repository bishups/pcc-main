module KitSchedulesHelper
  
  def kit_schedule_state_tag(ks)
    proc do
      if ks.state == ::KitSchedule::STATE_BLOCKED
        '<span class="label label-info">Blocked</span>'
      elsif ks.state == ::KitSchedule::STATE_ISSUED
        '<span class="label label-warning">Issued</span>'
       elsif ks.state == ::KitSchedule::STATE_ASSIGNED
        '<span class="label label-success">Assigned</span>'
      elsif ks.state == ::KitSchedule::STATE_OVERDUE
        '<span class="label label-danger">Overdue</span>'
      elsif ks.state == ::KitSchedule::STATE_CANCELLED
        '<span class="label label-danger">Cancelled</span>'
      elsif ks.state == ::KitSchedule::STATE_RETURNED
        '<span class="label label-success">Returned</span>'
      elsif ks.state == ::KitSchedule::STATE_RESERVED
        '<span class="label label-warning">Reserved</span>'
      elsif ks.state == ::KitSchedule::STATE_UNAVAILABLE_OVERDUE
        '<span class="label label-danger">Kit Overdue</span>'
      elsif ks.state == ::KitSchedule::STATE_UNDER_REPAIR
        '<span class="label label-danger">Under Repair</span>'
      elsif ks.state == ::KitSchedule::STATE_CLOSED
        '<span class="label label-default">Closed</span>'
      elsif prog.state == ::KitSchedule::STATE_AVAILABLE_EXPIRED
        '<span class="label label-danger">Available (Expired)</span>'
      else
        '<span class="label label-default">Unknown</span>'
      end
    end.call().html_safe
  end
end

