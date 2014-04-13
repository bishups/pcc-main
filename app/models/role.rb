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
  has_and_belongs_to_many :permissions
  has_many :access_privileges

  attr_accessible :name, :permission_ids, :permissions

  validates :name, :permissions, :presence => true

  ROLES = [
      {
          :name => "Super Admin",
          :desc => "Allows access to all functionalities.",
          :permissions => :all
      },
      {
          :name => "Center Organiser",
          :desc => "Allows access to particular center organiser.",
          :permissions => ["Teacher Scheduling","Venue Scheduling","Kit Scheduling"]
      },
      {
          :name => "Center Treasurer",
          :desc => "Allows access to particular center treasurer",
          :permissions => ["Venue Read"]
      },
      {
          :name => "Master Data Admin",
          :desc => "Allows access to Administration of Master Data.",
          :permissions => ["Master Data"]
      }
  ]

  def self.init_roles!
    Permission.init_permissions!
    ROLES.each do |r|
      if Role.where(:name => r[:name]).first().nil?
        Role.new do |role|
          role.name = r[:name]
          role.permissions = Permission.where(:name=>r[:permissions])
          role.save!
        end
      end
    end
  end

  rails_admin do
    navigation_label 'Access Privilege'
    weight 2
    list do
      field :name
      field :permissions
    end
    edit do
      ### do not allow user to change name of existing role
      #field :name
      field :permissions do
        inline_add do
          false
        end
      end
    end
  end


end

