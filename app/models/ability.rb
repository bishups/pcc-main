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
          # Ensure that the subject class has a belongs_to assosiation so that it can be filetered based on that.
          # For ex) If below rule has subject in permission as 'Venue' and resource allowed for the user is a particluat
          # center then it will look like
          #         can :manage, Venue, :center => @center ( Center the user is allowed to access )
          # So ENSURE TO HAVE A BELONGS TO ASSOSATION TO CENTER OR ANY OTHER RESOURCE USED TO CONFIGURE IN ROLES FOR THE
          # CLASS WHICH WE NEED CANCAN
          subject_class = permission.subject.constantize
          puts "######Inside permission loop #{ subject_class.reflections[:center] and subject_class.reflections[:center].macro == :belongs_to}  "
          if subject_class.reflections[:center] and subject_class.reflections[:center].macro == :belongs_to
            puts "Before can definition subject_class => #{subject_class} and center_id #{access_privilege.resource_id} "
            can :manage, subject_class, {:center_id => access_privilege.resource_id}
          elsif subject_class.reflections[:centers]
            can :manage, subject_class, {:centers => {:id => resource}}
          end

          #do |subject|
          #  if subject.respond_to?(:underscore)
          #    :center_id => resource
          #  else
          #
          #  end
          #
          #end
          can :manage, permission.subject, access_privilege.resource_type.underscore => access_privilege.resource
        elsif permission.subject and not access_privilege.resource
          # If we want to provide access of all the Venues across all center then you don't need to provide
          # resource type in the role

          can :manage, permission.subject.constantize

        elsif user.is_super_admin?
          # Super admin will have access to all the actions and models

          can :manage, :all

        end
      end
    end
  end
end
