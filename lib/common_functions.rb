module CommonFunctions
  def has_comments?
    if self.comments.nil? || self.comments.blank?
      self.errors[:comments] << " is mandatory field."
      return false
    end

    if (self.comments.casecmp("(Other) ") == 0)
      self.errors[:base] << "Please fill Details when selecting 'Other'."
      return false
    end
    true
  end

  def has_feedback?
    if self.feedback.nil? || self.feedback.blank?
      self.errors[:feedback] << " is mandatory field."
      return false
    end
    true
  end

  def load_comments!(params)
    self.comment_category = []
    self.comment_category << params[:comment_category] unless params[:comment_category].nil?
    self.comments = ""
    self.comments += "(" +  params[:comment_category] + ") " unless params[:comment_category].nil?
    self.comments += params[:comments] unless params[:comments].nil?
    self.feedback = params[:feedback] unless params[:feedback].nil?
  end

  def store_last_update!(user, from_state, to_state, event)
    self.last_updated_by_user = user
    # We are not relying on in-built table updated_at, in case the state machine transition differ from table transition
    self.last_updated_at = Time.zone.now
#    time_str = (Time.zone.now).strftime('%d %B %Y (%I:%M%P)')
#    self.last_update = "From #{from_state} to #{to_state} on #{event} at #{time_str}"
    if (from_state.casecmp("Unknown") == 0)
      self.last_update = "#{to_state}"
    else
      self.last_update = "#{from_state} to #{to_state}"
    end
  end
end
