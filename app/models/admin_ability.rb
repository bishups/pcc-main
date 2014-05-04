class AdminAbility
  include CanCan::Ability

  def initialize(user)
    can :access, :rails_admin if not user.accessible_centers.empty? # Only user's having at least one center will have this access.
    can :dashboard if user.is?(:super_admin) #Check for the count and User specific history.
    if user.is?(:super_admin)
      can :manage, :all
    end
    if user.is?(:kit_coordinator) or user.is?(:center_coordinator) # Remove the center co-ordinator
      can :manage, Kit, {:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:kit_coordinator][:text]).map(&:id).uniq}}   # Check for zonal co-ordinator
      can :read, Center    # Only for this center
      can :manage, KitItem
      # Gaurdian - needs to be from current center. Validation based on selected center.
      # Kit - Soft delete
      # Kit Item - Hard delete
    end

#    KitItemName - need to be renamed KitItemType
#    Only Super Admmin can do this. All can read.

    if user.is?(:venue_coordinator) or user.is?(:center_coordinator)       # or sector or zonal co-ordinator
      can :manage, [Venue],{:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:venue_coordinator][:text]).map(&:id).uniq}}  # Check for zonal co-ordinator
      can :read, Center   # Only for this center
    end
    if user.is?(:center_coordinator)
      can :manage, [User, AccessPrivilege]
      can :read, Role
      cannot [:create,:destroy], User
    end
    if user.is?(:zonal_coordinator)
      can :manage, Teacher, {:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:zonal_coordinator][:text]).map(&:id).uniq}}
      cannot [:create,:destroy], Teacher
      can :manage, [User], {:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:zonal_coordinator][:text]).map(&:id).uniq}}
      can :manage, Zone, {:id => Zone.by_centers(user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:zonal_coordinator][:text]).map(&:id).uniq)}
      cannot [:create,:destroy], [User,Zone]
      can :manage, [AccessPrivilege, Sector, Center, Pincode]
      can :read, Role
    end
    # Zone - Selected Sector.
    # ZOne - Can add / remove Sector for his zone. Show sectors of all the zone.

    #

    if user.is?(:zao)
      can :manage, User, {:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:zao][:text]).map(&:id).uniq}}
      cannot [:create,:destroy], User
      can :manage, [AccessPrivilege, Pincode]
      can :read, Role
    end
    if user.is?(:sector_coordinator)
      can :manage, [User], {:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]).map(&:id).uniq}}
      can :manage, Sector, {:id => Sector.by_centers(user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]).map(&:id).uniq)}
      cannot [:create,:destroy], [User,Sector]
      can :manage, [AccessPrivilege, Center, Pincode]
    end

    # Sector - ONly can view the sector.
    # ZOnal co- Can edit
    # Zone - read only


    # Center - Center co-ordna - Only read
    # All the centers of the sector and same as Zone
    # Sector - cord - Edit - Name, Readonly - Sector. All the pincodes of sector.
    # Zonal - All pincodes of Zone

    # Pincode - Super User
    # View pincode -
    # Location name can be edited by Zone / Sector / Center co-ordo.


    # User .
    # can view all the users in sector and zone. user with multile sectors.
    # New User - Edit link should be send to the Approver. Returning user can change the approver'e email and remmeber.
    # Soft delete for all.
    # Disable the user this for only Zonal and Sector co-ordinator. Shared user cannot be disabled.
    # All other data should be editable only by Super User. Zonal and Sector co-ordinator can only add access privilleges.
    #

    # Acess Prville
    # All the resource Sector and center below visible
    # Cannot Delete access privilleges of Teacher
    # User drop down - All the Users . In Dropdown show Name + Mobile.
    # Role - Below their Sector - until treasurer
    # Resource - Sector co-ordinatpr - only centers
    # Resource - Zonal co-ordinatpr - All resource. ( With in user access. )
    # Hard delete.

    # Teacher
    # Can be added only Super Admin
    # Soft Delete.
    # Show all the teacher;s having as loggeed in user. Include multiple ZOnes and Sector.
    # Sector Co-orditor - Center is considered  (Attached )

    # Sector / Zonal - Listing teachers
    # Attached - Zone and Center
    # Un Fit - Only Zone.
    # No Attached - Nothing needed.
    # User and T,no is not editatble
    # Status - Show all for super admin.
    # Program Type - Only by Super Admin. ( Hint - not needed if read only)
    # Sector Cordinot - Zone is read olnly
    # Zonal Corrdinator - With in my zone.

    # Super admin cannot remove Teacher in Access Privillege
    #
    # Comments - Only for Zonal co-ordinator
    #



    can :read, [Role,ProgramType]
    # ProgramType is missing in Menu
   #  can :manage, :all
  end

end
