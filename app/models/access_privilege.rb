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
  validate :is_role_valid?

  def role_name=(role_name)
    Role.where(:name => role_name ).first
  end

  def center_name=(center_name)
    Center.where(:name => center_name).first
  end

  def is_role_valid?
    role = self.role.name.parameterize.underscore.to_sym
    resource_type = self.resource.class.name.demodulize

    valid_roles =
    case resource_type
      when "Zone"
        [:zonal_coordinator, :zao]
      when "Sector"
        [:sector_coordinator]
      when "Center"
        [:center_coordinator, :volunteer_committee, :center_scheduler, :kit_coordinator, :venue_coordinator, :center_treasurer]
      else
        # teacher should not be set be set from here, TODO - remove it completely later
        []
    end
    if !valid_roles.include?(role)
      self.errors[:resource] << " does not match the specified role."
    end
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
