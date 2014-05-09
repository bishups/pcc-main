class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :set_current_user

  def set_current_user
    User.current_user = current_user
  end

  def search_keyword_available?
    !params[:keyword].to_s.empty?
  end

  def search_keyword_wc
    '%' + params[:keyword] + '%'
  end

end
