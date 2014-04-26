class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    user = User.from_omniauth(request.env["omniauth.auth"])
    if user.persisted?
      flash.notice = "Signed in Through Google!"
      sign_in_and_redirect user
    else
      session["devise.user_attributes"] = user.attributes.slice(*User.accessible_attributes)
      flash.notice = "You don't have account to the system, please fill in the below form and get approval. Please enter proper approver's email."
      redirect_to new_user_registration_url
    end
  end
end