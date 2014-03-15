module KitSchedulesHelper
  
  def kit_schedule_state_tag(ks)
    proc do
      if ks.blocked?
        '<span class="label label-info">Blocked</span>'
      elsif ks.issued?
        '<span class="label label-info">Issued</span>'
       elsif ks.assigned?
        '<span class="label label-info">Assigned</span>'  
      elsif ks.closed?
        '<span class="label label-success">Closed</span>'
      elsif ks.cancel?
        '<span class="label label-danger">Cancelled</span>'
      else
        '<span class="label label-default">Unknown</span>'
      end
    end.call().html_safe
  end

end
