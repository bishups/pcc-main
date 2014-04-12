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
        {:zonal_coordinator     => {:text => "Zonal Coordinator", :access_level => 5},
          :zao                  => {:text => "ZAO", :access_level => 4},
          :sector_coordinator   => {:text => "Sector Coordinator", :access_level => 3},
          :center_coordinator   => {:text => "Center Coordinator", :access_level => 2},
          :volunteer_committee  => {:text => "Volunteer Coordinator", :access_level => 1},
          :center_scheduler     => {:text => "Center Scheduler", :access_level => 0},
          :kit_coordinator      => {:text => "Kit Coordinator", :access_level => 0},
          :venue_coordinator    => {:text => "Venue Coordinator", :access_level => 0},
          :center_treasurer     => {:text => "Center Treasurer", :access_level => 0},
          :teacher              => {:text => "Teacher", :access_level => 0}
  }


  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :firstname, :lastname, :address, :phone, :mobile, :access_privilege_names, :type
  attr_accessible :access_privileges, :access_privileges_attributes
  #accepts_nested_attributes_for :access_privileges, allow_destroy: true

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

  def is?(for_role, options={})
    # convert to i
    for_center_ids = (options[:center_ids] || [options[:center_id]]).map(&:to_i)
    self.access_privileges.each do |ap|
      self_centers = []
      if ap.resource.class.name.demodulize == "Center"
        self_centers = [ap.resource]
      elsif ap.resource.class.name.demodulize == "Sector" || ap.resource.class.name.demodulize == "Zone"
        self_centers = ap.resource.centers
      end
      # if for given ap, self has >= centers than asked for
      if (for_center_ids.compact - self_centers.collect(&:id)).empty?
        #self_ah = (ROLE_ACCESS_HIERARCHY.select {|k, v| v[:text] == ap.role.name}).values.first
        self_ah = ROLE_ACCESS_HIERARCHY[ap.role.name.parameterize.underscore.to_sym]
        for_ah =  ROLE_ACCESS_HIERARCHY[for_role]
        # if for given ap, self has same role, or access_level > access_level than asked for
        if ((self_ah == for_ah) || self_ah[:access_level] > for_ah[:access_level])
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

  def resource_name(resource)
    type = resource.class.name.demodulize
    aps = self.access_privileges
    case type
      when "Zone"
        resource.zone.name
      when "Sector"
        resource.sector.name
      when "Center"
        resource.center.name
      else
        []
    end
  end

  def access_privileges_str(rails_admin)
    role_str = ""
    self.access_privileges.each {|ap|
      #role_path = rails_admin.show_path(:model_name => 'role', :id => ap.role.id)
      resource_path = rails_admin.show_path(:model_name => 'access_privilege', :id => ap.id)
      #role_str << %{ #{ap.role.name} => #{ap.resource.class.name.demodulize} (#{ap.resource.name}) <br>}
      #role_str << %{<a href=#{role_path}>#{ap.role.name}</a> => <a href=#{resource_path}>#{ap.resource.name}</a> <br>}
      role_str << %{<a href=#{resource_path}>#{ap.role.name} - #{ap.resource.name}</a> <br>}
    }
    role_str
  end

  rails_admin do
=begin
    configure :custom_access_privileges do
      pretty_value do
        ap_str = bindings[:object].access_privileges_str(bindings[:view].rails_admin)

        # bindings[:view].link_to "#{contractor.first_name} #{contractor.last_name}", bindings[:view].show_path('contractor', contractor.id)
        %{<div class="access_privilege_ap"> #{ap_str} </div >}
      end
      read_only true # won't be editable in forms (alternatively, hide it in edit section)
    end
=end

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

      #field :access_privileges do
      #  children_fields [:role, :resource]
      #end
      field :custom_access_privileges do
        pretty_value do
          ap_str = bindings[:object].access_privileges_str(bindings[:view].rails_admin)
          if ap_str.empty?
            ap_str = %{<a href=#{bindings[:view].rails_admin.new_path('access_privilege')}> + Add New </a>}
            #%{<div class='btn btn-primary btn-sm'> #{ap_str} </div >}
            %{ <div class="btn btn-sm" :hover> #{ap_str} </div>}
          else
            %{<div class="access_privilege_ap"> #{ap_str} </div >}
          end
        end
        read_only true # won't be editable in forms (alternatively, hide it in edit section)

        label "Access Privileges"
        help ""
      end
      #field :access_privileges  do
      #  def value
      #    bindings[:object].access_privileges #.each do {|ap| ap.role.name}
      #  end
      #end

    end
  end
end
