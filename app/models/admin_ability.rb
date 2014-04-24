class AdminAbility
  include CanCan::Ability

  def initialize(user)
    can :access, :rails_admin
    can :dashboard
   # can :manage, :all
    if user.is?(:super_admin)
      can :manage, :all
    end
    if user.is?(:kit_coordinator)
      can :manage, [Kit, KitItem]
    end
    if user.is?(:venue_coordinator)
      can :manage, [Venue]
    end
    if user.is?(:zonal_coordinator)
      can :update, [Teacher,User,Zone]
      can :manage, [AccessPrivilege,Sector,Center,Pincode]
    end
    if user.is?(:zao)
      can :update, User
      can :manage, [AccessPrivilege,Pincode]
    end
    if user.is?(:sector_coordinator)
      can :update, Sector
      can :manage, [AccessPrivilege,Center,Pincode]
    end

    can :manage, :all
  end

end