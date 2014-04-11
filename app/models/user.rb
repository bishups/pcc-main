# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string(255)
#  crm_user_id            :integer
#  firstname              :string(255)
#  lastname               :string(255)
#  address                :string(3000)
#  phone                  :string(255)
#  mobile                 :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :registerable

  has_many :access_privileges
  has_many :roles, :through => :access_privileges
  has_many :permissions, :through => :roles

  has_many :centers, :through => :access_privileges, :source => :resource, :source_type => 'Center'
  has_many :sectors, :through => :access_privileges, :source => :resource, :source_type => 'Sector'
  has_many :zones, :through => :access_privileges, :source => :resource, :source_type => 'Zone'

  has_many :sector_centers, :through => :sectors, :source => :centers
  has_many :zone_centers, :through => :sectors, :source => :centers
  has_many :zone_sectors, :through => :zones, :source => :sectors

  #has_many :teacher_schedules
  #has_many :teacher_slots

  ROLE_ACCESS_HIERARCHY =
        {:zonal_coordinator     => {:text => "Zonal Coordinator", :access_level => 5, :in_hierarchy => [:geography, :pcc]},
          :zao                  => {:text => "ZAO", :access_level => 4, :in_hierarchy => [:geography]},
          :sector_coordinator   => {:text => "Sector Coordinator", :access_level => 3, :in_hierarchy => [:geography, :pcc]},
          :center_coordinator   => {:text => "Center Coordinator", :access_level => 2, :in_hierarchy => [:geography] },
          :volunteer_committee  => {:text => "Volunteer Coordinator", :access_level => 1, :in_hierarchy => [:geography] },
          :center_scheduler     => {:text => "Center Scheduler", :access_level => 0, :in_hierarchy => [:geography] },
          :kit_coordinator      => {:text => "Kit Coordinator", :access_level => 0, :in_hierarchy => [:geography] },
          :venue_coordinator    => {:text => "Venue Coordinator", :access_level => 0, :in_hierarchy => [:geography] },
          :center_treasurer     => {:text => "Center Treasurer", :access_level => 0, :in_hierarchy => [:geography] },
          :teacher              => {:text => "Teacher", :access_level => 0, :in_hierarchy => [:pcc] }
  }


  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :firstname, :lastname, :address, :phone, :mobile, :access_privilege_names, :type
  attr_accessible :access_privileges_attributes
  accepts_nested_attributes_for :access_privileges

  validates :firstname,:email, :mobile, :presence => true

  validates :email, :uniqueness => true, :format => {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}
  validates :phone, :length => { is: 12}, :format => {:with => /0[0-9]{2,4}-[0-9]{6,8}/i}, :allow_blank => true
  validates :mobile, :length => { is: 10}, :numericality => {:only_integer => true }

  def access_privilege_names=(names)
    names.collect do |n|
      ap=self.access_privileges.new
      ap.role=Role.where(:name => n[:role_name] ).first
      ap.resource=Center.where(:name => n[:center_name] ).first
    end
  end

  def is_super_admin?
    self.roles.exists?(:name => "Super Admin")
  end

  def accessible_centers
    self.centers+self.sector_centers+self.zone_centers
  end

  def accessible_sectors
    self.sectors+self.zone_sectors
  end

  def accessible_zones
    self.zones
  end

  # usage -- check if user has role for specific resource
  # if user.is? :zonal_coordinator, :center_id => 10
  # if user.is? :zonal_coordinator, :center_ids => [1,2,3]
  # if user.is? :zonal_coordinator

  def is?(role, options={})
    # convert to i
    center_ids = (options[:center_ids] || [options[:center_id]]).map(&:to_i)
    self.access_privileges.each do |ap|
      accessisble_centers = []
      if ap.resource.class.name.demodulize == "Center"
        accessisble_centers = [ap.resource]
      elsif ap.resource.class.name.demodulize == "Sector" || ap.resource.class.name.demodulize == "Zone"
        accessisble_centers = ap.resource.centers
      end
      # if for given ap, self has >= centers than asked for
      if (center_ids.compact - accessisble_centers.collect(&:id)).empty?
        #self_ah = (ROLE_ACCESS_HIERARCHY.select {|k, v| v[:text] == ap.role.name}).values.first
        self_ah = ROLE_ACCESS_HIERARCHY[ap.role.name.parameterize.underscore.to_sym]
        ah =  ROLE_ACCESS_HIERARCHY[role]
        # if for given ap, self has >= access_level than asked for in all the hierarchies
        if (self_ah[:access_level] and self_ah[:access_level] >= ah[:access_level])  && (ah[:in_hierarchy] - self_ah[:in_hierarchy]).empty?
          return true
        end
      end
    end
    return false
  end

  def fullname
    "%s %s" % [self.firstname.to_s.capitalize, self.lastname.to_s.capitalize]
  end

  def access_to_resource?(resource)
    self.access_privileges.find_by_resource_type_and_resource_id(resource.class.to_s,resource.id)
  end

  def name
    self.fullname
  end

  def programs
    Program.all
  end

  def venues
    Venue.all
  end

  def kits
    Kit.all
  end

  def teachers
    Teacher.all
  end

  rails_admin do
    navigation_label 'Access Privilege'
    weight 0
    list do
      field :firstname
      field :lastname
      field :mobile
      field :email
      field :type
    end
    edit do
      group :default do
        label "User information"
        help "Please fill all informations related to user..."
      end
      field :firstname
      field :lastname
      field :address
      field :mobile
      field :phone do
        help "Optional. Format of stdcode-number (e.g, 0422-2515345)."
      end
      field :email do
        help "Required"
      end
      #field :type do
      #  label "Teacher"
      #  def render
      #    bindings[:view].render :partial => "user_type_checkbox", :locals => {:field => self, :f => bindings[:form]}
      #  end
      # end

      field :access_privileges

    end
  end
end
