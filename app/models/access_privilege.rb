# == Schema Information
#
# Table name: access_privileges
#
#  id            :integer          not null, primary key
#  role_id       :integer
#  user_id       :integer
#  resource_id   :integer
#  resource_type :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class AccessPrivilege < ActiveRecord::Base
  belongs_to :role
  belongs_to :user
  belongs_to :resource, :polymorphic => true
  has_many :permissions, :through => :role

  attr_accessible :user, :role_id, :resource_id, :resource_type, :role_name, :center_name

  def role_name=(role_name)
    Role.where(:name => role_name ).first
  end

  def center_name=(center_name)
    Center.where(:name => center_name).first
  end

  rails_admin do
    field :role do

    end
    field :resource
  end

end