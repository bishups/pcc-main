module CommonFunctions
  def has_comments?
    if self.comments.nil?
      self.errors[:comments] << " is mandatory field."
      return false
    end

    if (self.comments.casecmp("Other") == 0)
      self.errors[:comments] << " are mandatory when selecting 'Other'."
      return false
    end

    true
  end
end