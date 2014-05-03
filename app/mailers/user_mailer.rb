class UserMailer < ActionMailer::Base
  default :from => "info@pcc-admin.ishayoga.org"

  def email(user, from, to, on, additional_text, friendly_name_for_email)
    @user = user
    @from = from
    @to = to
    @additional_text = additional_text
    @friendly_name = friendly_name_for_email
    @url  = 'http://localhost:3000'
    mail(:to => @user.email, :subject => "#{@friendly_name[:text]} updated")
  end


  def sms(user, from, to, on, additional_text, friendly_name_for_sms)
    @user = user
    @from = from
    @to = to
    @additional_text = additional_text
    @friendly_name_for_sms = friendly_name_for_sms
    sms_email_id = "#{@user.mobile}.#{Rails.application.config.sms_country_username}@smscountry.net"
    mail(:to => sms_email_id, :subject => Rails.application.config.sms_country_username)
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
