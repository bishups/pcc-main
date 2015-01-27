class UserController < ApplicationController
  before_filter :authenticate_user!
  autocomplete :user, :email, :extra_data => [:mobile] ,:scopes => [:current_user_zone_users] , :display_value => :display_in_auto_complete

  def autocomplete_user_email
    term = params[:term]
    users = []
    if current_user.is?(:super_admin)
      users = User.where('email LIKE ?', "%#{term}%").order(:email)
      render :json => users.map { |user| {:id => user.id, :label => user.email, :value => user.email} }
    else
      users = current_user.all_zone_users.where('email LIKE ?', "%#{term}%").order(:email)
      users_collection = users.map do |user|
        if not ( user.is?(:teacher_training_department) or user.is?(:pcc_accounts) )
          {:id => user.id, :label => user.email, :value => user.email}
        end
      end
      render :json => users_collection.compact
    end
  end
end
