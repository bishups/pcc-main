class AdminAbility
  include CanCan::Ability

  def initialize(user)
    can :access, :rails_admin
    can :dashboard
    if user.is?(:super_admin)
      can :manage, :all
    end
    if user.is?(:kit_coordinator) or user.is?(:center_coordinator)
      can :manage, Kit, {:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:kit_coordinator][:text]).map(&:id).uniq}}
      can :read, Center
      can :manage, KitItem
    end
    if user.is?(:venue_coordinator) or user.is?(:center_coordinator)
      can :manage, [Venue],{:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:venue_coordinator][:text]).map(&:id).uniq}}
      can :read, Center
    end
    if user.is?(:center_coordinator)
      can :manage, [User, AccessPrivilege]
      cannot [:create,:destroy], User
    end
    if user.is?(:zonal_coordinator)
      can :manage, Teacher, {:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:zonal_coordinator][:text]).map(&:id).uniq}}
      cannot [:create,:destroy], Teacher
      can :manage, [User,Zone], {:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:zonal_coordinator][:text]).map(&:id).uniq}}
      cannot [:create,:destroy], [User,Zone]
      can :manage, [AccessPrivilege, Sector, Center, Pincode]
    end
    if user.is?(:zao)
      can :manage, User, {:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:zao][:text]).map(&:id).uniq}}
      cannot [:create,:destroy], User
      can :manage, [AccessPrivilege, Pincode]
    end
    if user.is?(:sector_coordinator)
      can :manage, [User,Sector], {:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]).map(&:id).uniq}}
      cannot [:create,:destroy], [User,Sector]
      can :manage, [AccessPrivilege, Center, Pincode]
    end

    # can :manage, :all
  end

end
