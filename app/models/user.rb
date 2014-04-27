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

module UserExtension
  def by_role(role_name)
    role=Role.where(:name => role_name).first
    if role
      find(:all, :conditions => ["access_privileges.role_id = ?", role.id])
    else
      find(:all)
    end
  end
end


class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :registerable, :omniauthable, :omniauth_providers => [:google_oauth2]

  has_many :access_privileges
  has_many :roles, :through => :access_privileges
  has_many :permissions, :through => :roles

  has_many :centers, :through => :access_privileges, :source => :resource, :source_type => 'Center', :extend => UserExtension
  has_many :sectors, :through => :access_privileges, :source => :resource, :source_type => 'Sector', :extend => UserExtension
  has_many :zones, :through => :access_privileges, :source => :resource, :source_type => 'Zone', :extend => UserExtension

  has_many :sector_centers, :through => :sectors, :source => :centers, :extend => UserExtension
  has_many :zone_centers, :through => :zones, :source => :centers, :extend => UserExtension
  has_many :zone_sectors, :through => :zones, :source => :sectors, :extend => UserExtension

  #has_many :teacher_schedules
  #has_many :teacher_slots

  ROLE_ACCESS_HIERARCHY =
      {
          :super_admin => {:text => "Super Admin", :access_level => 6, :group => [:pcc, :geography, :finance]},
          :zonal_coordinator     => {:text => "Zonal Coordinator", :access_level => 5, :group => [:pcc, :geography]},
          :zao                  => {:text => "ZAO", :access_level => 4, :group => [:geography]},
          :sector_coordinator   => {:text => "Sector Coordinator", :access_level => 3, :group => [:pcc, :geography]},
          :center_coordinator   => {:text => "Center Coordinator", :access_level => 2, :group => [:geography]},
          :volunteer_committee  => {:text => "Volunteer Committee", :access_level => 0, :group => [:geography]},
          :center_scheduler     => {:text => "Center Scheduler", :access_level => 0, :group => [:geography]},
          :kit_coordinator      => {:text => "Kit Coordinator", :access_level => 0, :group => [:geography]},
          :venue_coordinator    => {:text => "Venue Coordinator", :access_level => 0, :group => [:geography]},
          :center_treasurer     => {:text => "Center Treasurer", :access_level => 0, :group => [:geography]},
          :teacher              => {:text => "Teacher", :access_level => 0, :group => [:pcc]},
          # NOTE: when creating user-id corresponding to pcc_accounts/ finance_department, they need to be added to relevant zones.
          :pcc_accounts         => {:text => "PCC Accounts", :access_level => 0, :group => [:finance]},
          :finance_department   => {:text => "Finance Department", :access_level => 0, :group => [:finance]},
          :any                  => {:text => "Teacher", :access_level => -1, :group => []}
    }


  # Setup accessible (or protected) attributes for your model
  attr_accessor :username, :provider, :uid, :avatar, :approver_email, :message_to_approver
  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :firstname, :lastname, :address, :phone, :mobile, :access_privilege_names, :type
  attr_accessible :access_privileges, :access_privileges_attributes
  attr_accessible :username, :provider, :uid, :avatar, :approver_email, :message_to_approver

  accepts_nested_attributes_for :access_privileges, allow_destroy: true

  validates :firstname, :email, :mobile, :approver_email, :message_to_approver, :presence => true

  validates :email, :uniqueness => true, :format => {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}
  validates :phone, :length => {is: 12}, :format => {:with => /0[0-9]{2,4}-[0-9]{6,8}/i}, :allow_blank => true
  validates :mobile, :length => {is: 10}, :numericality => {:only_integer => true}
  validate :validate_approver_email, on: :create

  before_create do |user|
    if user.approver_email
      UserMailer.approval_email(user).deliver
    end
  end

  def validate_approver_email
    approver = User.where(:email => self.approver_email).first
    unless approver and (approver.is?(:zonal_coordinator) or approver.is?(:sector_coordinator))
      errors[:approver_email] << "is not valid. Either Email is in-correct or the provided email is not of a approver."
    end
  end

  def self.from_omniauth(auth)
    logger.debug("auth --> #{auth.inspect}")
    if user = User.find_by_email(auth.info.email)
      user.provider = auth.provider
      user.uid = auth.uid
      user
    else
      User.new(:email => auth.info.email, :firstname => auth.info.first_name, :lastname => auth.info.last_name)
    end
  end

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

  def accessible_center_ids(role_name=nil)
    centers = self.accessible_centers(role_name)
    centers = [centers] unless centers.class == Array
    centers.collect(&:id)
  end

  def accessible_centers(role_name=nil)
    self.centers.by_role(role_name) + self.sector_centers.by_role(role_name) +self.zone_centers.by_role(role_name)
  end

  def accessible_sectors(role_name=nil)
    self.sectors.by_role(role_name)+self.zone_sectors.by_role(role_name)
  end

  def accessible_zone_ids(role_name=nil)
    zones = self.accessible_zones(role_name)
    zones = [zones] unless zones.class == Array
    zones.collect(&:id)
  end

  def accessible_zones(role_name=nil)
    self.zones.by_role(role_name)
  end

=begin
  def accessible_center_ids(role)
    sector_center_ids = []
    self.accessible_sectors_ids(role).each { |sid|
      sector_center_ids += Center.where(:sector_id => sid).pluck(:id)
    }

    sector_center_ids +
        AccessPrivilege.where(:user_id => self.id, :role_id => role.id, :resource_type => 'Center').pluck(:resource_id)
  end


  def accessible_sectors_ids(role)
    zone_sector_ids = []
    self.accessible_zone_ids(role).each { |zid|
      zone_sector_ids += Sector.where(:zone_id => zid).pluck(:id)
    }
    zone_sector_ids +
        AccessPrivilege.where(:user_id => self.id, :role_id => role.id, :resource_type => 'Sector').pluck(:resource_id)
  end

  def accessible_zone_ids(role)
    AccessPrivilege.where(:user_id => self.id, :role_id => role.id, :resource_type => 'Zone').pluck(:resource_id)
  end
=end


  # usage -- checks if
  # 1. user has a specific role
  # --  if user.is? :zonal_coordinator
  # --  if user.is? :zonal_coordinator, :center_id => []
  # 2. user has a specific role for specified center(s)
  # --  if user.is? :zonal_coordinator, :center_id => 10
  # --  if user.is? :zonal_coordinator, :center_id => [1,2,3]
  # 3. user has a specific role for any (or all) of the specified center(s)
  # --  if user.is? :zonal_coordinator, :for => :any, :center_id => [1,2,3]
  # --  if user.is? :zonal_coordinator, :for => :all, :center_id => [1,2,3]
  # if :for option is not specified, be default it is assumed to be :for => :all
  #
  # NOTE: 12 Apr 14 - From rails_admin :teacher role cannot be associated with users via access_privileges
  # 1. because teacher checks can be handled simply by checking with current_user.teacher.id, rather than
  # going through the more complicated is? routine.
  # 2. teachers are associated separately with center(s) through the teacher admin interface.
  def is?(for_role, options={})
    for_center_ids = []
    if options.has_key?(:center_id)
      for_center_ids = options[:center_id].class == Array ? options[:center_id] : [options[:center_id]]
      for_center_ids = for_center_ids.map(&:to_i).compact
    end
    for_all = (options.has_key?(:for) && options[:for] == :any) ? false : true
    # HACK - for_all is set true if we are looking at [] centers.
    for_all = true if for_center_ids.empty?
    self.access_privileges.each do |ap|
      self_centers = []
      if ap.resource.class.name.demodulize == "Center"
        self_centers = [ap.resource]
      elsif ap.resource.class.name.demodulize == "Sector" || ap.resource.class.name.demodulize == "Zone"
        self_centers = ap.resource.centers
      end
      # if for given ap,
      # a. for_all if self has >= centers than asked for
      # b. for_any if self has any center that was asked for
      self_center_ids = self_centers.collect(&:id)
      if (for_all && (for_center_ids - self_center_ids).empty?) ||
         (!for_all && (for_center_ids - self_center_ids) != for_center_ids )
        #self_ah = (ROLE_ACCESS_HIERARCHY.select {|k, v| v[:text] == ap.role.name}).values.first
        self_ah = ROLE_ACCESS_HIERARCHY[ap.role.name.parameterize.underscore.to_sym]
        for_ah =  ROLE_ACCESS_HIERARCHY[for_role]
        # if for given ap, self has same role, or access_level > access_level than asked for, and part of all groups
        if (self_ah == for_ah) || ((self_ah[:access_level] > for_ah[:access_level])  &&  (for_ah[:group] - self_ah[:group]).empty?)
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
            #ap_str = %{<a href=#{bindings[:view].rails_admin.new_path('access_privilege')}> + Add New </a>}
            #%{<div class='btn btn-primary btn-sm'> #{ap_str} </div >}
            #%{ <div class="btn btn-sm" :hover> #{ap_str} </div>}
            %{<a href=#{bindings[:view].rails_admin.new_path('access_privilege')}><button class="btn btn-sm btn-primary" :hover> + Add New Access Privilege </button></a>}
          else
            %{<div class="access_privilege_ap"> #{ap_str} </div >}
          end
        end
      #  read_only true # won't be editable in forms (alternatively, hide it in edit section)

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
