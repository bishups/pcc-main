# == Schema Information
#
# Table name: permissions
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  cancan_action :string(255)
#  subject       :string(255)
#

class Permission < ActiveRecord::Base
  attr_accessible :name
  has_and_belongs_to_many :functional_groups
  has_and_belongs_to_many :roles
  validates :name, :cancan_action, :subject, :presence => true

  attr_accessible :name, :role_ids, :functional_group_ids,:cancan_action, :subject

  FUNCTIONAL_GROUPS_PERMISSIONS =  {"Scheduling" => [:all => :create],
                                    "Master Data" => {:center => :manage,:sector => :manage,:zone => :manage },
                                    "Venue Read" => {:venue => :read},
                                    "Venue Scheduling" => {:venue_schedule => :manage}
                                    }

  def self.init_permissions!
    FUNCTIONAL_GROUPS_PERMISSIONS.each do |functional_group,permissions|
      fg=FunctionalGroup.new(:name => functional_group)
      permissions.each { |permission| fg.permissions << Permission.new({:name => permission}) }
      fg.save
      puts fg.errors.messages
    end
  end

  def cancan_action_enum
    %w(manage read create update delete)
  end

  def subject_enum
    %w(Venue Teacher Kit)
  end

  rails_admin do
    navigation_label 'Access Privilege'
    weight 1
    list do
      field :name
      field :cancan_action
      field :subject
    end
    edit do
      field :name
      field :cancan_action
      field :subject
    end
  end


end
