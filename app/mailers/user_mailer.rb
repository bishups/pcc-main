class UserMailer < ActionMailer::Base
  default :from => "info@pcc-admin.ishayoga.org"

  def email(object, user, from, to, on, additional_text)
    @object = object
    @user = user
    @from = from
    @to = to
    @additional_text = additional_text
    @url  = Rails.application.routes.default_url_options[:host]
    mail(:to => @user.email, :subject => "#{@object.friendly_first_name_for_email + @object.friendly_second_name_for_email} updated")
  end


  def sms(object, user, from, to, on, additional_text)
    @object = object
    @user = user
    @from = from
    @to = to
    @additional_text = additional_text
    sms_email_id = "#{@user.mobile}.#{Rails.application.config.sms_country_username}@smscountry.net"
    mail(:to => sms_email_id, :subject => Rails.application.config.sms_country_username)
  end

  def approval_email(user)
    @user = user
    @url  = 'http://localhost:3000'
    mail(:to => @user.approver_email, :subject => "Approval Email for User - #{@user.firstname}")
  end

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
