module KitSchedulesHelper
  
  def kit_schedule_state_tag(ks)
    proc do
      if ks.blocked?
        '<span class="label label-info">Blocked</span>'
      elsif ks.issued?
        '<span class="label label-info">Issued</span>'
       elsif ks.assigned?
        '<span class="label label-info">Assigned</span>'  
      elsif ks.under_repair?
        '<span class="label label-warning">Under Repair</span>'
      elsif ks.incomplete_return?
        '<span class="label label-warning">Incomplete Return</span>'
      elsif ks.unavailable?
        '<span class="label label-danger">Unavailable</span>'
      elsif ks.cancelled?
        '<span class="label label-danger">Cancelled</span>'
      elsif ks.returned_and_checked?
        '<span class="label label-success">Returned And Checked</span>'  
      else
        '<span class="label label-default">Unknown</span>'
      end
    end.call().html_safe
  end

end
