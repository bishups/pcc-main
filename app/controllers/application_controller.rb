class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :set_current_user
  #before_filter :check_password_validity

  def set_current_user
    User.current_user = current_user
  end

  def search_keyword_available?
    !params[:keyword].to_s.empty?
  end

  def search_keyword_wc
    '%' + params[:keyword] + '%'
  end

  def check_password_validity
    if user_signed_in? and 
      (controller_name.to_s !~ /Registrations/i) and 
      current_user.force_password_reset?
        redirect_to edit_registration_path(User)
    end
  end
end
