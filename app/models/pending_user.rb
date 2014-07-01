class PendingUser < User


rails_admin do

  navigation_label 'Access Privilege'
  visible do
    bindings[:controller].current_user.is?(:super_admin) or bindings[:controller].current_user.is?(:zonal_coordinator) or bindings[:controller].current_user.is?(:sector_coordinator) or bindings[:controller].current_user.is?(:teacher_training_department) or bindings[:controller].current_user.is?(:zao)
  end
  weight 0
  list do
    field :firstname
    field :lastname
    field :mobile
    field :email
    field :type
  end
  edit do
    group :default do
      label "User information"
      help "Please fill all informations related to user..."
    end
    field :firstname do
      read_only do
        not bindings[:controller].current_user.is?(:super_admin)
      end
    end
    field :lastname do
      read_only do
        not bindings[:controller].current_user.is?(:super_admin)
      end
    end
    field :address do
      read_only do
        not bindings[:controller].current_user.is?(:super_admin)
      end
    end
    field :mobile do
      read_only do
        not bindings[:controller].current_user.is?(:super_admin)
      end
    end
    field :phone do
      read_only do
        not bindings[:controller].current_user.is?(:super_admin)
      end
      help "Optional. Format of stdcode-number (e.g, 0422-2515345)."
    end
    field :email do
      read_only do
        not bindings[:controller].current_user.is?(:super_admin)
      end
      help "Required"
    end
    field :enable
  end
end


end