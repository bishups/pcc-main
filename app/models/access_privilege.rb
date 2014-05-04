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

  attr_accessible :user, :role_id, :resource_id, :resource_type, :role_name, :center_name, :resource, :role, :user, :user_id
  validate :is_role_valid?
  before_destroy :is_teacher_attached?

  scope :by_role,lambda { |role_name| joins(:role).where('roles.name = ?', role_name) }

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
        [:zonal_coordinator, :zao, :pcc_accounts, :finance_department]
      when "Sector"
        [:sector_coordinator]
      when "Center"
        [:center_coordinator, :volunteer_committee, :center_scheduler, :kit_coordinator, :venue_coordinator, :center_treasurer, :teacher]
      else
        []
    end
    if !valid_roles.include?(role)
      self.errors[:resource] << " does not match the specified role."
    end
  end

  def is_teacher_attached?
    teacher_role = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:teacher][:text])
    if self.role.id == teacher_role.id && self.resource_type == "Center"
      teacher = Teacher.find_by_user_id(self.user_id)
      if CentersTeachers.where('teacher_id = ? AND center_id = ?', teacher.id, self.resource_id).count > 0
        self.errors[:base] << "Cannot delete access privilege for teacher when attached to the center. Please unattach from center."
        return false
      end
    end
  end

  rails_admin do
    navigation_label 'Access Privilege'
    weight 1
    #visible false
    #object_label_method do
    #  :role_name
    #end
    list do
      field :user
      field :role
      field :resource
    end
    edit do
      field :user do
        inline_edit false
        inline_add false
      end
      field :role do
        inline_edit false
        inline_add false
        # from https://github.com/sferik/rails_admin/wiki/Associations-scoping
        associated_collection_cache_all false  # REQUIRED if you want to SORT the list as below
        associated_collection_scope do
          role = bindings[:object]
          Proc.new { |scope|
            # scoping all roles currently, let's just remove the teacher record for now, later can add security based scoping also
            scope = scope.where("name IS NOT IN (?)", [::User::ROLE_ACCESS_HIERARCHY[:teacher][:text], ::User::ROLE_ACCESS_HIERARCHY[:any][:text]]) #if role.present?
            # sorting over association does not work for now -- see open issue  https://github.com/sferik/rails_admin/issues/1395
            scope = scope.reorder("role.name ASC")
          }
        end
      end
      field :resource
    end
  end

  def role_name
    self.role.name if self.role
  end

end
