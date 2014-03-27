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
  has_many :resources, :through => :access_privileges
  has_many :teacher_schedules
  has_many :teacher_slots

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :firstname, :lastname, :address, :phone, :mobile, :access_privilege_names, :type
  attr_accessible :access_privileges_attributes
  accepts_nested_attributes_for :access_privileges

  validates :firstname,:email,:presence => true

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
      field :phone
      field :email
      field :type do
        label "Teacher"
        def render
          bindings[:view].render :partial => "user_type_checkbox", :locals => {:field => self, :f => bindings[:form]}
        end
      end

      field :access_privileges

    end
  end
end
