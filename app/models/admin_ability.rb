class AdminAbility
  include CanCan::Ability

  def initialize(user)
    can :access, :rails_admin if not user.accessible_centers.empty? # Only user's having at least one center will have this access.
    can :dashboard #Check for the count and User specific history.

    if user.is?(:super_admin)
      can :manage, :all
      cannot :delete, Teacher
    else
      can :read, User, {:id => user.accessible_centers.map(&:user_ids).flatten.uniq}
      can :read, Center, {:id => user.accessible_centers}

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
        can [:read,:update], [User], {:id => user.accessible_centers.map(&:user_ids).flatten.uniq}
        can :manage, Sector, {:id => user.accessible_sectors}
        cannot [:create, :destroy], Sector
        can :manage, Center, {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]).map(&:id).uniq}
        can :manage, AccessPrivilege, {:resource_type => "Center", :resource_id => user.accessible_centers}
        cannot :destroy, AccessPrivilege, { :role_id => Role.where(:name=>User::ROLE_ACCESS_HIERARCHY[:teacher][:text]).first.id }
        can [:read, :update], Teacher, {:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]).map(&:id).uniq}}
      end

      if user.is?(:zonal_coordinator) or user.is?(:zao)
        can :manage, Zone,{:id => user.accessible_zones}
        cannot [:create, :destroy], [Zone]
      end


      # New User - Edit link should be send to the Approver. Returning user can change the approver'e email and remmeber.
      # Disable the user this for only Zonal and Sector co-ordinator. Shared user cannot be disabled.
      # All other data should be editable only by Super User. Zonal and Sector co-ordinator can only add access privilleges.


      # User drop down - All the Users . In Dropdown show Name + Mobile.
      # Role - Below their Sector - until treasurer


    end
  end

end
