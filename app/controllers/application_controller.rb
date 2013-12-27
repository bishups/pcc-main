class ApplicationController < ActionController::Base
  protect_from_forgery

  def current_role
    if user_signed_in?
      current_user.role_manager
    else
      User.new().role_manager   # Guest
    end
  end
  helper_method :current_role

  def search_keyword_available?
    !params[:keyword].to_s.empty?
  end

  def search_keyword_wc
    '%' + params[:keyword] + '%'
  end

end
