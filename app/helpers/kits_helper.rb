module KitsHelper

  def kit_state_tag(ks)
    
    proc do
      if ks.available?
        '<span class="label label-info">Available</span>'
      elsif ks.under_repair?
        '<span class="label label-danger">Under Repair</span>'
      elsif ks.unavailable?
        '<span class="label label-info">unavailable</span>'  
       else
        "" 
      end
    end.call().html_safe
  end
end