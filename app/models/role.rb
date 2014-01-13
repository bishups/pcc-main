# == Schema Information
#
# Table name: roles
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Role < ActiveRecord::Base

  has_and_belongs_to_many :users

  ROLE_SUPER_ADMIN = "super_admin"
  ROLE_USER_ADMIN = "user_admin"
  ROLE_MASTER_DATA_ADMIN = "master_admin"

  ROLES = [
      {
          :role => ROLE_SUPER_ADMIN,
          :name => "Super Admin",
          :desc => "Allows access to all functionalities."
      },
      {
          :role => ROLE_USER_ADMIN,
          :name => "User Admin",
          :desc => "Allows access to User Management related functionalities."
      },
      {
          :role => ROLE_MASTER_DATA_ADMIN,
          :name => "Master Data Admin",
          :desc => "Allows access to Administration of Master Data."
      }
  ]

  def self.init_roles!
    ROLES.each do |r|
      if Role.where(:name => r[:role]).first().nil?
        Role.new do |role|
          role.name = r[:role]
          role.save!
        end
      end
    end
  end

  def self.find_meta(name)
    ROLES.find { |e| e[:role] == name }
  end
end

