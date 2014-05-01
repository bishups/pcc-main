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
    return true
  end

  def has_feedback?
    if self.feedback.nil? || self.feedback.blank?
      self.errors[:feedback] << " is mandatory field."
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
#    time_str = (Time.zone.now).strftime('%d %B %Y (%I:%M%P)')
#    self.last_update = "From #{from_state} to #{to_state} on #{event} at #{time_str}"
    if (from_state.casecmp("Unknown") == 0)
      self.last_update = " #{to_state}"
    else
      self.last_update = " #{from_state} to #{to_state}"
    end
  end

  def clear_last_update!
    self.last_updated_by_user = nil
    self.last_updated_at = nil
    self.last_update = nil
  end

  def notify(from_state, to_state, on_event, center_ids)

    model = self.class.name
    from = from_state != :any ? [from_state, "any"] : ["any"]
    to = to_state != :any ? [to_state, "any"] : ["any"]
    on = on_event != :any ? [on_event, "any"] : ["any"]
    center_ids = center_ids.class == Array ? center_ids : [center_ids]

    notify = {}
    notifications = Notification.where('model IS ? AND from_state IN (?) AND to_state IN (?)  AND on_event IN (?) ', model, from, to, on).all
    notifications.each { |n|
      r = Role.find(n.role_id)
      case r.name
        when ::User::ROLE_ACCESS_HIERARCHY[:zonal_coordinator][:text],
            ::User::ROLE_ACCESS_HIERARCHY[:zao][:text],
            ::User::ROLE_ACCESS_HIERARCHY[:pcc_accounts][:text],
            ::User::ROLE_ACCESS_HIERARCHY[:finance_department][:text]
          # search by zones
          users = r.users.by_zones(center_ids).uniq
        when ::User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]
          # search by sectors
          users = r.users.by_sectors(center_ids).uniq
        else
          # search by centers
          users = r.users.by_centers(center_ids).uniq
      end


      # for each of the users, add the flags send_sms, send_email, and additional_text
      # check if the user already exists, if it does make a OR of send_sms, send_email. Add additional text
      # insert into the hash
      users.each { |user|
        old_value = notify[user] if notify.has_key?(user)
        new_value = {:send_sms => n.send_sms, :send_email => n.send_email, :additional_text => (n.additional_text.nil? || n.additional_text.blank? ? "" : "(#{n.additional_text})") }
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
      self.notify_user(user, model, from_state, to_state, on_event, value)
    }
  end


  def notify_user(user, model, from, to, on, value)

    if(value.send_email == true){

       User_Mailer.email(user, from, to, value.additional_text, self.friendly_name).deliver 
  }

  if(value.send_sms == true){

   User_Mailer.sms(user, from, to, value.additional_text, self.friendly_name_for_sms).deliver  
  }



=begin
Program #1 Uyir Nokkam Cbe-City starting 01 Apr 2014

if value.send_email == true
Email - template (html format) user.email_id

Namaskaram,
#{self.friendly_name}
Status: #{from} to #{to}
unless value.additional_text.nil?
#{value.additional_text}
end

Please log-in to http://localhost:3000/ for details.

Pranam,
Isha Foundation


if value.send_sms == true
Sms - template (text format) user.mobile

Namaskaram, #{self.friendly_name_for_sms}, Status: #{from} to #{to}
unless value.additional_text.nil?
#{value.additional_text}
end
Pranam,
Isha Foundation

=end

  end



end
