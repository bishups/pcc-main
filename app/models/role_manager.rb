# Helper methods for Role Management
class RoleManager
  
  def initialize(user)
    @user = user
  end

  def is_super_admin?
    @user.roles.where(:name => ::Role::ROLE_SUPER_ADMIN).count() > 0
  end

  def has_manager_role?()
  end

  def has_admin_role?()
  end

  def has_role?(role_name)
    @user.roles.where(:name => role_name).count() > 0
  end

  # This method ignores invalid role names
  def has_roles?(role_names = [])
    @roles = ::Role.where(:name => role_names)
    @user.roles.where(:id => @roles.map(&:id)).count() == @roles.count()
  end

  def has_any_role?(role_names = [])
    @user.roles.where(:role_id => ::Role.where(:name => role_names).map(&:role_id)).count() > 0
  end

  def roles
    @user.roles
  end

  def role_names
    self.roles.map(&:name)
  end

  def add_role(role_name)
    @role = ::Role.where(:name => name).first()
    @user.roles << @role unless @role.nil? or @user.roles.include?(@role)
  end

  def remove_role(name)
    @role = ::Role.where(:name => name).first()
    @user.roles.delete(@role) unless @role.nil?
  end

end