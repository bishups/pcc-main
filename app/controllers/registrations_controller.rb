class RegistrationsController < Devise::RegistrationsController

  def new
    self.resource = resource_class.new(session["devise.user_attributes"])
    respond_with self.resource
  end

  protected

  def after_inactive_sign_up_path_for(resource)
    '/registration_confirmation'
  end

  def sign_up(resource_name, resource)
    # sign_in(resource_name, resource)
  end

  def after_sign_up_path_for(resource)
    flash.alert =  "Your account is waiting for Approval. Please login once you have been approved"
    root_url
  end

end
