class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :firstname, :lastname, :address, :phone, :mobile

  has_and_belongs_to_many :roles

  def role_manager
    @role_manager ||= ::RoleManager.new(self)
  end

  def fullname
    "%s %s" % [self.firstname.capitalize, self.lastname.capitalize]
  end

end
