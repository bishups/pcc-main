class UserMailer < ActionMailer::Base
  default from: "ishapcc@gmail.com"

def welcome_email(user, transitionValue, event)
    @user = user
    mail(to: @user.email, subject: 'Program Announced')
  end
end
