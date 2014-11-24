class AdminAbility
  include CanCan::Ability

  def initialize(user)
    can :access, :rails_admin if not user.access_privileges .empty? # Only user's having at least one center will have this access.
    can :dashboard #if user.is?(:kit_coordinator) or user.is?(:venue_coordinator) or user.is?(:teacher_training_department)
    can :manage, PendingUser, {:approver_email => user.email}
    if user.is?(:super_admin)
      can :manage, :all
      cannot [:create,:update, :destroy], [Timing, Role, Permission ]
      can :read, Role, { :name => User::ROLE_ACCESS_HIERARCHY.dup.delete_if{|k,v|  [:teacher].include?(k) }.map{|k,v| v[:text]} }
    else
      can :read, User, {:id => user.accessible_centers.map(&:user_ids).flatten.uniq }
      can :read, Center, {:id => user.accessible_centers}
      can :read, Pincode
      can :read, Zone
      can :read, ProgramType

      if user.is?(:kit_coordinator)
        can :manage, Kit, {:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:kit_coordinator][:text]).map(&:id).uniq}}
        can :manage, KitItem, {:kit => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:kit_coordinator][:text]).map(&:kits).flatten.map(&:id).uniq}}
        can :read, KitItemType
      end

      if user.is?(:venue_coordinator)
        can :manage, [Venue], {:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:venue_coordinator][:text]).map(&:id).uniq}}
      end

      if user.is?(:center_coordinator)
        can :read, Pincode
      end

      if user.is?(:sector_coordinator)
        can [:read,:update], [User], {:id => user.accessible_centers.map(&:user_ids).flatten.uniq + User.where(:approver_email => user.email).uniq.map(&:id) }
        can [:read], Sector, {:id => user.accessible_sectors.map(&:id)}
        can :read, Zone, {:id => Zone.by_centers(user.accessible_centers.uniq).uniq }
        can :read, Center, {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]).map(&:id).uniq}
        can :manage, AccessPrivilege, {:resource_type => "Center", :resource_id => user.accessible_centers}
        #can [:read, :update], Teacher, {:centers => {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]).map(&:id).uniq}}
        can [:read, :update], Teacher, {:zone => {:id => user.accessible_zones(User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]).map(&:id).uniq}}
        #   can [:read, :update], Teacher.joins(:centers).where(["centers.id in (?)", user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]).map(&:id)]).uniq
        can :read, Role, { :name => User::ROLE_ACCESS_HIERARCHY.dup.map{|k,v| v[:text] if [:center_coordinator, :volunteer_committee, :center_scheduler, :kit_coordinator, :venue_coordinator, :treasurer].include?(k)}.compact}
      end

      if user.is?(:zonal_coordinator) or user.is?(:zao)
        can :manage, AccessPrivilege, {:resource_type => "Center", :resource_id => user.accessible_centers}
        can :manage, AccessPrivilege, {:resource_type => "Sector", :resource_id => user.accessible_sectors}
        can :manage, AccessPrivilege, {:resource_type => "Zone", :resource_id => user.accessible_zones}
        can [:read], Zone, {:id => user.accessible_zones.map(&:id) }
        can :manage, Center, {:id => user.accessible_centers(User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]).map(&:id).uniq}
      #  can  [:create, :destroy], Sector, {:id => user.accessible_sectors.map(&:id)}
        can :manage, Pincode
        can :read, ProgramDonation
        can :read, Role, { :name => User::ROLE_ACCESS_HIERARCHY.dup.map{|k,v| v[:text] if [:center_coordinator, :volunteer_committee, :center_scheduler, :kit_coordinator, :venue_coordinator, :treasurer, :zao, :sector_coordinator].include?(k)}.compact}
      end

      if user.is?(:teacher_training_department)
        can :manage, Teacher
        can :read, Center
        can [:read,:update], [User], {:id => user.accessible_centers.map(&:user_ids).flatten.uniq + User.where(:approver_email => user.email).uniq.map(&:id) }
      end

      # User drop down - All the Users . In Dropdown show Name + Mobile.
      # Role - Below their Sector - until treasurer


    end
  end

end
