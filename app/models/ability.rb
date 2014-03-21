class Ability
  include CanCan::Ability

  def initialize(user)
    #user.access_privileges.each do |access_privilege|
    #  can :manage, :all, :center_id => access_privilege.resource_id
    #end
    user.access_privileges.each do |access_privilege|
      #  puts "Inside access_privilege loop   #{access_privilege.permissions.count} "
      access_privilege.permissions.each do |permission|
        #  puts "Inside access_privilege loop #{permission.subject},  #{access_privilege.resource} "
        if access_privilege.resource and permission.subject
          # Ensure that the subject class has assosiation so to Center.
          # For ex) If below rule has subject in permission as 'Venue' and resource allowed for the user is a particluar
          # center then it will look like
          #         can :manage, Venue, :center => @center ( Center the user is allowed to access )
          # So ENSURE TO HAVE ASSOSATION TO CENTER

          # Array of Center is calculated from the user's access privilege
          access_to_resource = []
          if access_privilege.resource.class.name.demodulize == "Center"
            access_to_resource = [access_privilege.resource]
          elsif access_privilege.resource.class.name.demodulize == "Sector" || access_privilege.resource.class.name.demodulize == "Zone"
            access_to_resource = access_privilege.resource.centers
          elsif not user.is_super_admin?
            raise " Namaskaram. You don't have access to any Zone / Sector / Center. Please contact administrator."
          end

          subject_class = permission.subject.constantize
          if subject_class.reflections[:center] and subject_class.reflections[:center].macro == :belongs_to
            can permission.cancan_action.downcase.to_sym, subject_class, {:center => access_to_resource}
          elsif subject_class.reflections[:centers]
            can permission.cancan_action.downcase.to_sym, subject_class, {:centers => {:id => access_to_resource}}
          end
        elsif user.is_super_admin?
          # Super admin will have access to all the actions and models
          can :manage, :all
        end
      end
    end
  end
end
