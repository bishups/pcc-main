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

  validates :role,:resource, :presence => true

  attr_accessible :user, :role_id, :resource_id, :resource_type, :role_name, :center_name, :resource, :role

  def role_name=(role_name)
    Role.where(:name => role_name ).first
  end

  def center_name=(center_name)
    Center.where(:name => center_name).first
  end

  rails_admin do
    visible false
    object_label_method do
      :role_name
    end
    field :role do
      inline_edit do
        false
      end
      inline_add do
        false
      end
    end
    field :resource
  end

  def role_name
    self.role.name if self.role
  end

end
