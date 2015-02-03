# == Schema Information
#
# Table name: roles
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  sync_id    :integer
#

class Role < ActiveRecord::Base

  has_and_belongs_to_many :permissions
  has_many :access_privileges
  has_many :users, :through => :access_privileges do

    def by_centers(centers=[])
      find(:all, :conditions => ["access_privileges.resource_type = 'Center' and access_privileges.resource_id in (?)", centers])
    end

    def by_sectors(objs=[])
      if objs.first.class.name == "Center"
        objs=Sector.by_centers(objs)
      end
      find(:all, :conditions => ["access_privileges.resource_type = 'Sector' and access_privileges.resource_id in (?)", objs])
    end

    def by_zones(objs=[])
      if objs.first.class.name == "Center"
        objs=Zone.by_centers(objs)
      end
      if objs.first.class.name == "Sector"
        objs=Zone.by_sectors(objs)
      end
      find(:all, :conditions => ["access_privileges.resource_type = 'Zone' and access_privileges.resource_id in (?)", objs])
    end

  end

  attr_accessible :name, :permission_ids, :permissions
  validates :name, :uniqueness => true

 # validates :name, :permissions, :presence => true

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
          :name => "Treasurer",
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
    visible do
       bindings[:controller].current_user.is?(:super_admin)
     end
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

