class UserController < ApplicationController

  autocomplete :user, :email, :extra_data => [:mobile] ,:scopes => [:current_user_zone_users] , :display_value => :display_in_auto_complete

  def autocomplete_user_email
    term = params[:term]
    users = []
    if current_user.is?(:super_admin)
      users = User.where('email LIKE ?', "%#{term}%").order(:email)
    else
      users = current_user.zone_users.where('email LIKE ?', "%#{term}%").order(:email)
    end
    render :json => users.map { |user| {:id => user.id, :label => user.email, :value => user.email} }
  end

end
