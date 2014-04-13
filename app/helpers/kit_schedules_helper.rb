module KitSchedulesHelper
  
  def kit_schedule_state_tag(ks)
    proc do
      if ks.state == ::KitSchedule::STATE_BLOCKED
        '<span class="label label-info">Blocked</span>'
      elsif ks.state == ::KitSchedule::STATE_ISSUED
        '<span class="label label-info">Issued</span>'
       elsif ks.state == ::KitSchedule::STATE_ASSIGNED
        '<span class="label label-info">Assigned</span>'  
      elsif ks.state == ::KitSchedule::STATE_OVERDUE
        '<span class="label label-success">Closed</span>'
      elsif ks.state == ::KitSchedule::STATE_CANCELLED
        '<span class="label label-danger">Cancelled</span>'
      elsif ks.state == ::KitSchedule::STATE_CLOSED
        '<span class="label label-info">Closed</span>'
      else
        '<span class="label label-default">Unknown</span>'
      end
    end.call().html_safe
  end
end

