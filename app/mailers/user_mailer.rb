class UserMailer < ActionMailer::Base
  default :from => "info@pcc-admin.ishayoga.org"

  def email(user, model, from, to, on, additional_text, friendly_name)
    @user = user
    @from = from
    @to = to
    @additional_text = additional_text
    @friendly_name = friendly_name
    @url  = 'http://localhost:3000'
    mail(:to => @user.email, :subject => "Program change - #{@friendly_name}")
  end


  def sms(user, model, from, to, on, additional_text, friendly_name_for_sms)
    @user = user
    @from = from
    @to = to
    @additional_text = additional_text
    @friendly_name_for_sms = friendly_name_for_sms
    mail(:to => @user.mobile."#{smscountry_username}"@smscountry.net, :subject => "Program announced - #{@friendly_name_for_sms}")
  end

end
