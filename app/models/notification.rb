# == Schema Information
#
# Table name: notifications
#
#  id              :integer          not null, primary key
#  model           :string(255)
#  from_state      :string(255)
#  to_state        :string(255)
#  on_event        :string(255)
#  role_id         :integer
#  send_sms        :boolean
#  send_email      :boolean
#  additional_text :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Notification < ActiveRecord::Base
  belongs_to :role
  attr_accessible :role

  attr_accessible :additional_text, :from_state, :model, :on_event, :role_id, :send_email, :send_sms, :to_state

  validates :model, :from_state, :to_state, :on_event, :role_id,  :presence => true
  validates :role_id, :uniqueness => {:scope => [:model, :from_state, :to_state, :on_event]}

  rails_admin do
    navigation_label 'Admin'
    weight 2
    list do
      field :model
      field :from_state
      field :to_state
      field :on_event
      field :role
    end
    edit do
      field :model
      field :from_state
      field :to_state
      field :on_event
      field :role do
        inline_add false
        inline_edit false
      end
      field :send_email
      field :send_sms
      field :additional_text
    end
  end
end
