class UserController < ApplicationController

  autocomplete :user, :email, :extra_data => [:mobile] , :display_value => :display_in_auto_complete

end
