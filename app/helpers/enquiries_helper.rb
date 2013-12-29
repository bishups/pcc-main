module EnquiriesHelper
  
  def enquiry_state_tag(enquiry)
    state_tag(enquiry.state.capitalize)
  end

end
