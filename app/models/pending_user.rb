# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string(255)
#  crm_user_id            :integer
#  firstname              :string(255)
#  lastname               :string(255)
#  address                :string(3000)
#  phone                  :string(255)
#  mobile                 :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  type                   :string(255)
#  deleted_at             :datetime
#  enable                 :boolean          default(FALSE)
#  approver_email         :string(255)
#  message_to_approver    :text
#  approval_email_sent    :boolean          default(FALSE)
#  password_reset_at      :datetime
#  provider               :string(255)
#  sync_ts                :string(255)
#  sync_id                :string(255)
#

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
