class AdminAbility
  include CanCan::Ability

  def initialize(user)
    can :access, :rails_admin if not user.accessible_centers.empty? # Only user's having at least one center will have this access.
    can :dashboard #Check for the count and User specific history.
    can :manage, PendingUser, {:approver_email => user.email}
    if user.is?(:super_admin)
      can :manage, :all
      cannot :destroy, Teacher
      cannot [:create,:update, :destroy], [Role. Permission, ]
    else
      can :read, User, {:id => user.accessible_centers.map(&:user_ids).flatten.uniq }
      can :read, Center, {:id => user.accessible_centers}
      can :read, Pincode
      can :read, Role

      if user.is?(:kit_coordinator)
        can :manage, Kit, {:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:kit_coordinator][:text]).map(&:id).uniq}}
        can :manage, KitItem, {:kit => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:kit_coordinator][:text]).map(&:kits).flatten.map(&:id).uniq}}
        can :read, KitItemType
      end

      if user.is?(:venue_coordinator)
        can :manage, [Venue], {:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:venue_coordinator][:text]).map(&:id).uniq}}
      end

      if user.is?(:center_coordinator)
        can :update, Pincode
      end

      if user.is?(:sector_coordinator)
        can [:read,:update], [User], {:id => user.accessible_centers.map(&:user_ids).flatten.uniq + User.where(:approver_email => user.email).uniq.map(&:id) }
        can [:read,:update], Sector, {:id => user.accessible_sectors.map(&:id)}
        can :read, Zone, {:id => Zone.by_centers(user.accessible_centers.uniq).uniq }
        can :manage, Center, {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]).map(&:id).uniq}
        can :manage, AccessPrivilege, {:resource_type => "Center", :resource_id => user.accessible_centers}
        can [:read, :update], Teacher, {:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]).map(&:id).uniq}}
      end
      if user.is?(:zonal_coordinator) or user.is?(:zao)
        can :manage, AccessPrivilege, {:resource_type => "Center", :resource_id => user.accessible_centers}
        can :manage, AccessPrivilege, {:resource_type => "Zone", :resource_id => user.accessible_zones}
        can [:read,:update], Zone, {:id => user.accessible_zones.map(&:id) }
        can  [:create, :destroy], Sector, {:id => user.accessible_sectors.map(&:id)}
      end

      # User drop down - All the Users . In Dropdown show Name + Mobile.
      # Role - Below their Sector - until treasurer


    end
  end

end
