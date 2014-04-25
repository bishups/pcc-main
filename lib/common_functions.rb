module CommonFunctions
  def has_comments?
    if (self.comment_type.nil?)
      self.errors[:comment_type] << " is mandatory field."
      return false
    end

    if (self.comment_type.text.casecmp("Other") == 0  && self.comments.nil?)
      self.errors[:comments] << " is mandatory field."
      return false
    end
    true
  end
end