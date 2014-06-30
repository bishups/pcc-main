module CommonFunctions
  def has_comments?
    if self.comments.nil? || self.comments.blank?
      self.errors[:comments] << " cannot be blank"
      return false
    end

    if (self.comments.casecmp("(Other) ") == 0)
      self.errors[:base] << "Please fill Details when selecting 'Other'."
      return false
    end
    return true
  end

  def has_feedback?
    if self.feedback.nil? || self.feedback.blank?
      self.errors[:feedback] << " cannot be blank"
      return false
    end
    return true
  end

  def load_comments!(params)
    self.comment_category = []
    self.comment_category << params[:comment_category] unless params[:comment_category].nil?
    self.comments = ""
    self.comments += "(" +  params[:comment_category] + ") " unless params[:comment_category].nil?
    self.comments += params[:comments] unless params[:comments].nil?
    self.feedback = params[:feedback] unless params[:feedback].nil?
  end

  def clear_comments!
    self.comments = self.feedback = ""
  end

  def store_last_update!(user, from_state, to_state, event)
    self.last_updated_by_user = user
    # We are not relying on in-built table updated_at, in case the state machine transition differ from table transition
    self.last_updated_at = Time.zone.now
    self.last_update = " " + self.update_str(from_state, to_state, event)
    self.log_last_activity(user, from_state, to_state, event, self.last_updated_at)
  end

  def update_str(from_state, to_state, event)
#    if (from_state.casecmp("Unknown") == 0)
#      "#{to_state}"
#    else
      "#{from_state} to #{to_state}"
#    end
  end

  def clear_last_update!
    self.last_updated_by_user = nil
    self.last_updated_at = nil
    self.last_update = nil
  end

  def log_last_activity(user, from, to, on, date = Time.zone.now)
    activity = ::ActivityLog.new
    activity.user = user
    activity.model_type = self.class.name
    #activity.model_type = "ProgramTeacherSchedule" if activity.model_type == "TeacherSchedule" and !self.program.nil?
    #activity.model_type = "TeacherSchedule" if activity.model_type == "ProgramTeacherSchedule" and self.program.nil?
    activity.model_id =  self.id
    activity.date = date.nil? ? Time.zone.now : date
    activity.text1 = self.friendly_first_name_for_email
    activity.text2 = " #{self.friendly_second_name_for_email} from #{self.update_str(from, to, on)}."

    # user, date, model_id, model_type, text
    activity.save
    unless activity.errors.nil?
      # TODO - some error handling or log msg?
    end
  end


  def notify(from_state, to_state, on_event, centers, teachers = [])

    model = self.class.name
    from = from_state != :any ? [from_state, "any"] : ["any"]
    to = to_state != :any ? [to_state, "any"] : ["any"]
    on = on_event != :any ? [on_event, "any"] : ["any"]
    centers = centers.class == Array ? centers : [centers]
    teachers = teachers.class == Array ? teachers : [teachers]

    notify = {}
    notifications = Notification.where('model = ? AND from_state IN (?) AND to_state IN (?)  AND on_event IN (?) ', model, from, to, on).all
    notifications.each { |n|
      r = Role.find(n.role_id)
      case r.name
        when ::User::ROLE_ACCESS_HIERARCHY[:zonal_coordinator][:text],
            ::User::ROLE_ACCESS_HIERARCHY[:full_time_teacher_scheduler][:text],
            ::User::ROLE_ACCESS_HIERARCHY[:zao][:text],
            ::User::ROLE_ACCESS_HIERARCHY[:pcc_accounts][:text],
            ::User::ROLE_ACCESS_HIERARCHY[:finance_department][:text],
          ::User::ROLE_ACCESS_HIERARCHY[:teacher_training_department][:text]
          # search by zones
          users = r.users.by_zones(centers).uniq
        when ::User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]
          # search by sectors
          users = r.users.by_sectors(centers).uniq
        when ::User::ROLE_ACCESS_HIERARCHY[:teacher][:text]
          if teachers.empty?
            # search by centers
            users = r.users.by_centers(centers).uniq
          else
            # specific teachers only
            users = teachers.map{|t| t.user}
          end
        else
          # search by centers
          users = r.users.by_centers(centers).uniq
      end

      if self.methods.include?(:update_users_for_notification!)
        updated_users = self.update_users_for_notification!(users, r, from, to, on, centers, teachers)
        users = updated_users
      end

      # for each of the users, add the flags send_sms, send_email, and additional_text
      # check if the user already exists, if it does make a OR of send_sms, send_email. Add additional text
      # insert into the hash
      users.each { |user|
        old_value = notify.has_key?(user) ? notify[user] : nil
        new_value = {:send_sms => n.send_sms, :send_email => n.send_email, :additional_text => (n.additional_text.nil? || n.additional_text.blank? ? "" : "#{n.additional_text}") }
        if old_value.nil?
          old_value = new_value
        else
          old_value[:send_sms] |= new_value[:send_sms]
          old_value[:send_email] |= new_value[:send_email]
          old_value[:additional_text] += new_value[:additional_text]
        end
        notify[user] = old_value
      }
    }

    notify.each_pair {|user, value|
      self.notify_user(user, from_state, to_state, on_event, value)
    }
  end


  def notify_user(user, from, to, on, value)
    UserMailer.email(self, user, from, to, on, value[:additional_text]).deliver if value[:send_email]
    UserMailer.sms(self, user, from, to, on, value[:additional_text]).deliver if value[:send_sms]
    self.log_notify(user, from, to, on, value[:additional_text]) if value[:send_email] || value[:send_sms]
  end


  def log_notify(user, from, to, on, additional_text)
    notification = ::NotificationLog.new
    notification.user = user
    notification.model_type = self.class.name
    #notification.model_type = "ProgramTeacherSchedule" if notification.model_type == "TeacherSchedule" and !self.program.nil?
    #notification.model_type = "TeacherSchedule" if notification.model_type == "ProgramTeacherSchedule" and self.program.nil?
    notification.model_id = self.id
    notification.date = Time.zone.now
    notification.text1 = self.friendly_first_name_for_email
    notification.text2 = " #{self.friendly_second_name_for_email} changed from #{self.update_str(from, to, on)}."
    notification.text2 += " #{additional_text.chomp('.')}." unless additional_text.blank?
    # user, date, model_id, model_type, text
    notification.save
    unless notification.errors.nil?
      # TODO - some error handling or log msg?
    end
  end

  def record_state
    ReportStateRecord.new do |rs|
      rs.record_name = self.class.name
      rs.record_id = self.id
      rs.state = self.state
      rs.save!
    end
  end


end
