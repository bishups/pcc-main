class UserMailer < ActionMailer::Base
  default :from => "info@pcc-admin.ishayoga.org"

  def approval_email(user)
    @user = user
    @url  = 'http://localhost:3000'
    mail(:to => @user.approver_email, :subject => "Approval Email for User - #{@user.firstname}")
  end

end
