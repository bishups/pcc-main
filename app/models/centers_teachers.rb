# == Schema Information
#
# Table name: centers_teachers
#
#  id         :integer          not null, primary key
#  center_id  :integer
#  teacher_id :integer
#

class CentersTeachers < ActiveRecord::Base
  # attr_accessible :title, :body

=begin
  after_create :create_access_privilege
  after_update :update_access_privilege
  after_destroy :destroy_access_privilege


  def create_access_privilege
    role = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:teacher][:text])
    teacher = Teacher.find(self.teacher_id)
    AccessPrivilege.create({ :role_id => role.id, :user_id => teacher.user.id, :resource_id => self.center_id, :resource_type => "Center" })
  end

  def update_access_privilege
    # this should not be called for now
    raise "error"
  end


  def destroy_access_privilege
    role = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:teacher][:text])
    teacher = Teacher.find(self.teacher_id)
    AccessPrivilege.where('role_id = ? AND user_id = ? AND resource_id = ? AND resource_type = ?', role.id, teacher.user.id, self.center_id, "Center").delete
  end



  after_save :update_access_privileges
  after_destroy :destroy_access_privileges


  def update_access_privilege
    role = Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:teacher][:text])
    accessible_centers = self.user.accessible_center_ids(role)
    updated_centers = self.center_ids
    centers_to_remove = accessible_centers - updated_centers
    centers_to_add = updated_centers - accessible_centers

    access_privileges_to_add = []
    centers_to_add.each { |cid|
      access_privileges_to_add << { :role_id => role.id, :user_id => self.user.id, :resource_id => cid, :resource_type => "Center" }
    }
    AccessPrivilege.create(access_privileges_to_add)

    AccessPrivilege.delete.where('id IN (?)',centers_to_remove)
  end

  def destroy_access_privilege
    role = ::User::ROLE_ACCESS_HIERARCHY[:teacher][:text])
    accessible_centers = self.user.accessible_center_ids(role)
    AccessPrivilege.delete.where('id IN (?)', accessible_centers)
  end
=end
end
