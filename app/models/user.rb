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
#  type                   :string(255)
#  deleted_at             :datetime
#  enable                 :boolean          default(FALSE)
#  approver_email         :string(255)
#  message_to_approver    :text
#  approval_email_sent    :boolean          default(FALSE)
#  password_reset_at      :datetime
#  provider               :string(255)
#  sync_ts                :string(255)
#  sync_id                :string(255)
#

module UserExtension
  def by_role(role_name)
    current_role_values = User::ROLE_ACCESS_HIERARCHY.select { |k, v| v[:text] == role_name }.values
    if not current_role_values.empty?
      current_role_access_level = current_role_values.first[:access_level]
      # Take all the roles above the current role's access level, including the current role.
      # So that while getting centers for zonal co-ordinator, will be available even if we check it for kit co-ordinator
      role_names = User::ROLE_ACCESS_HIERARCHY.select { |k, v| v[:access_level] >= current_role_access_level }.values.map { |a| a[:text] }
      puts role_names.inspect
      role_ids=Role.where(:name => role_names).map(&:id)
      find(:all, :conditions => ["access_privileges.role_id in (?)", role_ids])
    else
      find(:all)
    end
  end

  def by_group(group_name)
    current_group_values = User::ROLE_ACCESS_HIERARCHY.select { |k, v| v[:group].include?(group_name) }.values
    if not current_group_values.empty?
      role_names = current_group_values.map { |a| a[:text] }
      puts role_names.inspect
      role_ids=Role.where(:name => role_names).map(&:id)
      find(:all, :conditions => ["access_privileges.role_id in (?)", role_ids])
    else
      []
    end
  end
end


class User < ActiveRecord::Base
  include CommonFunctions

#  require Rails.root.join('lib', 'devise', 'encryptors', 'md5')

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :timeoutable,
         :recoverable, :rememberable, :trackable, :registerable, :omniauthable, :omniauth_providers => [:google_oauth2]

  acts_as_paranoid

  STATE_UNKNOWN             = "Unknown"
  STATE_REQUESTED_APPROVAL  = "Requested Approval"
  STATE_APPROVED            = "Approved"

  EVENT_CREATE              = "Create"
  EVENT_APPROVE             = "Approve"

  has_many :notification_logs, :dependent => :destroy
  has_many :activity_logs, :dependent => :destroy
  attr_accessible :notification_logs, :notification_log_ids, :activity_logs, :activity_log_ids
  has_many :access_privileges, :dependent => :destroy
  has_many :roles, :through => :access_privileges
  has_many :permissions, :through => :roles

  has_many :centers, :through => :access_privileges, :source => :resource, :source_type => 'Center', :extend => UserExtension
  has_many :sectors, :through => :access_privileges, :source => :resource, :source_type => 'Sector', :extend => UserExtension
  has_many :zones, :through => :access_privileges, :source => :resource, :source_type => 'Zone', :extend => UserExtension

  has_many :all_zones,:through => :centers, :source => :zone, :uniq => true

  has_many :sector_centers, :through => :sectors, :source => :centers, :extend => UserExtension
  has_many :zone_centers, :through => :zones, :source => :centers, :extend => UserExtension
  has_many :zone_sectors, :through => :zones, :source => :sectors, :extend => UserExtension

  has_many :zone_center_users, :through => :zone_centers, :source => :users
  has_many :zone_sector_users, :through => :zone_sectors, :source => :users
  has_many :zone_users, :through => :zones, :source => :users
  has_many :all_zone_users, :through => :all_zones, :source => :users


  has_many :teachers, :dependent => :destroy

  #has_many :teacher_schedules
  #has_many :teacher_slots

  ROLE_ACCESS_HIERARCHY =
      {
          :super_admin => {:text => "Super Admin", :access_level => 6, :group => [:geography, :finance, :training]},
          :zonal_coordinator     => {:text => "Zonal Coordinator", :access_level => 5, :group => [:geography]},
          :zao                  => {:text => "ZAO", :access_level => 4, :group => [:geography]},
          :sector_coordinator   => {:text => "Sector Coordinator", :access_level => 3, :group => [:geography]},
          :center_coordinator   => {:text => "Center Coordinator", :access_level => 2, :group => [:geography]},
          :volunteer_committee  => {:text => "Volunteer Committee", :access_level => 0, :group => [:geography]},
          :center_scheduler     => {:text => "Center Scheduler", :access_level => 0, :group => [:geography]},
          :kit_coordinator      => {:text => "Kit Coordinator", :access_level => 0, :group => [:geography]},
          :venue_coordinator    => {:text => "Venue Coordinator", :access_level => 0, :group => [:geography]},
          :treasurer            => {:text => "Treasurer", :access_level => 0, :group => [:geography]},
          :teacher              => {:text => "Teacher", :access_level => 0, :group => [:geography]},
          # NOTE: when creating user-id corresponding to teacher_training_department/ pcc_accounts/ finance_department/ program_announcement, they need to be added to relevant zones.
          :teacher_training_department     => {:text => "Teacher Training Department", :access_level => 0, :group => [:training]},
          :pcc_accounts         => {:text => "PCC Accounts", :access_level => 0, :group => [:finance]},
          :finance_department   => {:text => "Finance Department", :access_level => 0, :group => [:finance]},
          # Dummy group is just a place-holder group, which can be used for all roles which are not related by any hierarchy.
          :program_announcement    => {:text => "Program Announcement", :access_level => 0, :group => [:dummy]},
          :pcc_department         => {:text => "PCC Department", :access_level => 0, :group => [:pcc_requests]},
          :pcc_break_approver         => {:text => "PCC Break Approver", :access_level => 0, :group => [:pcc_requests]},
          :pcc_travel         => {:text => "PCC Travel", :access_level => 0, :group => [:pcc_requests]},
          :pcc_travel_approver      => {:text => "PCC Travel Approver", :access_level => 0, :group => [:pcc_requests]},
          :pcc_travel_vendor         => {:text => "PCC Travel Vendor", :access_level => 0, :group => [:pcc_vendor]},
          :help_desk            => { :text => "Help Desk", :access_level => 0, :group => [:help_desk] },
          :any                  => {:text => "Any", :access_level => -1, :group => []}
    }


  # Setup accessible (or protected) attributes for your model
  attr_accessor :username, :uid
  attr_accessible :email, :password, :password_confirmation, :remember_me, :enable, :approval_email_sent, :receive_email, :receive_sms
  attr_accessible :firstname, :lastname, :address, :phone, :mobile, :access_privilege_names, :type
  attr_accessible :access_privileges, :access_privileges_attributes
  attr_accessible :username, :provider, :uid, :approver_email, :message_to_approver

  accepts_nested_attributes_for :access_privileges, allow_destroy: true

  validates :approver_email, :message_to_approver, :presence => true, :on => :create, :unless => Proc.new { User.current_user.is_super_admin? if User.current_user }
  validates :email, :format => {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}
  validates_uniqueness_of :email, :scope => :deleted_at
  validates :phone, :length => {is: 12}, :format => {:with => /0[0-9]{2,4}-[0-9]{6,8}/i}, :allow_blank => true
  validates :mobile, :length => {is: 10}, :numericality => {:only_integer => true}
  validates_uniqueness_of :mobile, :scope => :deleted_at
  validate :validate_approver_email, :on => :create, :unless => Proc.new { User.current_user.is_super_admin? if User.current_user }

  normalize_attributes :approver_email, :email, :firstname, :lastname, :address, :mobile, :phone

  before_save do |user|
    logger.error("Inside User model before save. Values of user.email = #{user.email} and user.enabled? == #{user.enabled?} ")
    if not user.enabled?
      user.type = "PendingUser"
    else
      user.type = nil
    end
    logger.error("Inside User model before save after setting values. Values of user.email = #{user.email} and user.enable == #{user.enable}  and user.type == #{user.type}")
    self.password_reset_at = Time.now if self.encrypted_password_changed?
  end

  after_create do |user|
    user.reload
    UserMailer.approval_email(user).deliver
    user.log_notify(user, STATE_UNKNOWN, STATE_REQUESTED_APPROVAL, EVENT_CREATE, "Approver email: #{user.approver_email}")
    user.update_attribute(:approval_email_sent, true)
  end

  after_save  do |user|
    if user.enable_changed? && user.enable == true
      UserMailer.approved_email(user).deliver
      user.log_notify(user, STATE_REQUESTED_APPROVAL, STATE_APPROVED, EVENT_APPROVE, "")
    end
  end

  def all_users_under_zone
    self.zone_users + self.zone_sector_users + self.zone_center_users
  end


  def force_password_reset?
    self.password_reset_at.nil? or ((Time.now - self.password_reset_at) > 30.days)
  end

  def validate_approver_email
    approver = User.where(:email => self.approver_email.strip).first
    unless approver and (approver.is?(:super_admin) or approver.is?(:teacher_training_department) or approver.is?(:sector_coordinator))
      errors[:approver_email] << "is not valid. Either Email is in-correct or the provided email is not of a approver."
    end
  end

  def self.from_omniauth(auth)
    user = nil
    if user = User.find_by_email(auth.info.email)
      user.provider = auth.provider
      user.uid = auth.uid
      user
    else
     user= User.new(:email => auth.info.email, :firstname => auth.info.first_name, :lastname => auth.info.last_name, :provider => auth.provider)
     user.provider = auth.provider
    end
    user
  end

  def enabled?
    self.enable
  end

  def active_for_authentication?
    super && self.enabled? # i.e. super && self.is_active
  end

  def inactive_message
    if !enabled?
      :not_approved
    else
      super # Use whatever other message
    end
  end

  def access_privilege_names=(names)
    names.collect do |n|
      ap=self.access_privileges.new
      ap.role=Role.where(:name => n[:role_name]).first
      ap.resource=Center.where(:name => n[:center_name]).first
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

  def accessible_center_ids_by_group(group_name=nil)
    centers = self.accessible_centers_by_group(group_name)
    centers = [centers] unless centers.class == Array
    centers.collect(&:id)
  end

  def accessible_centers(role_name=nil)
    if self.is?(:super_admin)
      Center.all
    else
      self.centers.by_role(role_name) + self.sector_centers.by_role(role_name) +self.zone_centers.by_role(role_name)
    end
  end

  def accessible_centers_by_group(group_name=nil)
    if self.is?(:super_admin)
      Center.all
    else
      self.centers.by_group(group_name) + self.sector_centers.by_group(group_name) +self.zone_centers.by_group(group_name)
    end
  end

  def accessible_sectors(role_name=nil)
    if self.is?(:super_admin)
      Sector.all
    else
      self.sectors.by_role(role_name)+self.zone_sectors.by_role(role_name)
    end
  end

  def accessible_sectors_by_group(group_name=nil)
    if self.is?(:super_admin)
      Sector.all
    else
      self.sectors.by_group(group_name)+self.zone_sectors.by_group(group_name)
    end
  end

  def accessible_zone_ids(role_name=nil)
    zones = self.accessible_zones(role_name)
    zones = [zones] unless zones.class == Array
    zones.collect(&:id)
  end

  def accessible_zones(role_name=nil)
    if self.is?(:super_admin)
      Zone.all
    else
      self.zones.by_role(role_name)
    end
  end

  def accessible_zones_by_group(group_name=nil)
    if self.is?(:super_admin)
      Zone.all
    else
      self.zones.by_group(group_name)
    end
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
  # 4. user is in specific group(s)
  # -- if user.is? :any, :in_group => :geography
  # NOTE: you should use :in_group option only with :any role. It can be though combined with :center_id option
  #
  # NOTE: 12 Apr 14 - From rails_admin :teacher role cannot be associated with users via access_privileges
  # 1. because teacher checks can be handled simply by checking with current_user.teacher.id, rather than
  # going through the more complicated is? routine.
  # 2. teachers are associated separately with center(s) through the teacher admin interface.
  def is?(for_role, options={})
    for_center_ids = []
    in_groups = []
    if options.has_key?(:center_id)
      for_center_ids = options[:center_id].class == Array ? options[:center_id] : [options[:center_id]]
      for_center_ids = for_center_ids.map(&:to_i).compact
    end
    if options.has_key?(:in_group)
      in_groups = options[:in_group].class == Array ? options[:in_group] : [options[:in_group]]
    end

    for_all = (options.has_key?(:for) && options[:for] == :any) ? false : true
    # HACK - for_all is set true if we are looking at [] centers.
    for_all = true if for_center_ids.empty?
    self.access_privileges.each do |ap|
      # HACK - to allow super-admin to pass all checks
      if ap.role.name.parameterize.underscore.to_sym == :super_admin
        return true
      end
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
        self_ah_groups = self_ah[:group]
        for_ah_groups = in_groups == [] ? for_ah[:group] : in_groups
        # if for given ap, self has same role, or access_level > access_level than asked for, and part of all groups
        if (self_ah == for_ah) || ((self_ah[:access_level] > for_ah[:access_level])  &&  (for_ah_groups - self_ah_groups).empty?)
          return true
        end
      end
    end
    return false
  end

  def url
    RailsAdmin::Engine.routes.url_helpers.show_url(model_name: 'user', id: self.id)
  end

  def friendly_first_name_for_email
    "User ##{self.id}"
  end

  def friendly_second_name_for_email
    " #{self.fullname}"
  end

  def friendly_name_for_sms
    "User ##{self.id} #{self.fullname}"
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
      if ap.resource
        role_str << %{<a href=#{resource_path}>#{ap.role.name} - #{ap.resource.name}</a> <br>}
      else
        role_str << %{<a> #{ap.role.name} </a> <br>}
      end
    }
    role_str
  end

  def display_in_auto_complete
    "#{email}"
  end

  # this is a cron job, run through whenever gem
  # from the config/schedule.rb file
  def self.send_pending_approval_emails
    users = User.where("approval_email_sent = ?", false).all
    users.each {|user|
      UserMailer.approval_email(user).deliver
      user.log_notify(user, STATE_UNKNOWN, STATE_REQUESTED_APPROVAL, EVENT_CREATE, "Approver email: #{user.approver_email}")
      user.update_attribute(:approval_email_sent, true)
    }
  end

  # def password_salt
  #   'no salt'
  # end
  #
  # def password_salt=(new_salt)
  # end

  rails_admin do

    navigation_label 'Access Privilege'
    visible do
      bindings[:controller].current_user.is?(:sector_coordinator)
    end
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
      field :firstname do
        read_only do
          not ( bindings[:controller].current_user.is?(:super_admin) or bindings[:controller].current_user.is?(:zao) )
        end
      end
      field :lastname do
        read_only do
          not ( bindings[:controller].current_user.is?(:super_admin) or bindings[:controller].current_user.is?(:zao) )
        end
      end
      field :address do
        read_only do
          not ( bindings[:controller].current_user.is?(:super_admin) or bindings[:controller].current_user.is?(:zao) )
        end
      end
      field :mobile do
        read_only do
          not ( bindings[:controller].current_user.is?(:super_admin) or bindings[:controller].current_user.is?(:zao) )
        end
      end
      field :phone do
        read_only do
          not ( bindings[:controller].current_user.is?(:super_admin) or bindings[:controller].current_user.is?(:zao) )
        end
        help "Optional. Format of stdcode-number (e.g, 0422-2515345)."
      end
      field :email do
        read_only do
          not ( bindings[:controller].current_user.is?(:super_admin) or bindings[:controller].current_user.is?(:zao) )
        end
        help "Required"
      end
      field :password do
        read_only do
          not ( bindings[:controller].current_user.is?(:super_admin) or bindings[:controller].current_user.is?(:zao) )
        end
        help "Required"
      end
      field :password_confirmation do
        read_only do
          not ( bindings[:controller].current_user.is?(:super_admin) or bindings[:controller].current_user.is?(:zao) )
        end
        help "Required"
      end
      field :enable do
        read_only do
          not ( bindings[:controller].current_user.is?(:super_admin) or bindings[:controller].current_user.is?(:zao) )
        end
      end
      field :receive_email do
        read_only do
          not ( bindings[:controller].current_user.is?(:super_admin) or bindings[:controller].current_user.is?(:zao) )
        end
      end
      field :receive_sms do
        read_only do
          not ( bindings[:controller].current_user.is?(:super_admin) or bindings[:controller].current_user.is?(:zao) )
        end
      end
      field :access_privileges
      #field :custom_access_privileges do
      #  read_only true
      #  pretty_value do
      #    ap_str = bindings[:object].access_privileges_str(bindings[:view].rails_admin)
      #    if ap_str.empty?
      #      #ap_str = %{<a href=#{bindings[:view].rails_admin.new_path('access_privilege')}> + Add New </a>}
      #      #%{<div class="access_privilege_ap"> <a href=#{bindings[:view].rails_admin.new_path('access_privilege')}><button class="btn btn-sm btn-primary" :hover> + Add New Access Privilege </button></a></div >}
      #      # HACK - putting a button over the link is not working - it re-directs to user update, instead of going to add access privilege
      #      %{<div class="access_privilege_ap"> <a href=#{bindings[:view].rails_admin.new_path('access_privilege')}> + Add New Access Privilege </a></div >}
      #    else
      #      %{<div class="access_privilege_ap"> #{ap_str} </div >}
      #    end
      #  end
      ##  read_only true # won't be editable in forms (alternatively, hide it in edit section)
      #  label "Access Privileges"
      #  help ""
      #end

    end
  end

  #### Hack used to set Current User ######

  class << self
    def current_user=(user)
      Thread.current[:current_user] = user
    end

    def current_user
      Thread.current[:current_user]
    end
  end

end
