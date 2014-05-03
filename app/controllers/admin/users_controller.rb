class Admin::UsersController < ApplicationController
  
  def index
    @page = (params[:page] || 1).to_i
    @per_page = (params[:per_page] || 50).to_i

    @users = User.order('LOWER(email) ASC').paginate(:page => @page, :per_page => @per_page)
    @users = @users.where('email LIKE ? or firstname LIKE ? or lastname LIKE ?', 
      search_keyword_wc, search_keyword_wc, search_keyword_wc) if search_keyword_available?

    respond_to do |format|
      format.html
    end
  end

end
