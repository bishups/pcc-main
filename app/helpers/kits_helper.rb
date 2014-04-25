module KitsHelper

  def kit_state_tag(ks)
    
    proc do
      if ks.state == ::Kit::STATE_AVAILABLE
        '<span class="label label-info">Available</span>'
      elsif  ks.state == ::Kit::STATE_UNDER_REPAIR
        '<span class="label label-danger">Under Repair</span>'
      elsif ks.state == ::Kit::STATE_UNAVAILABLE
        '<span class="label label-info">Unavailable</span>'
       else
        '<span class="label label-default">Unknown</span>'
       end
    end.call().html_safe
  end
end