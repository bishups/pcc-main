RailsAdmin.config do |config|
  # or somethig more dynamic
  config.main_app_name = Proc.new { |controller| [ "PCC", "Administration BackOffice - #{controller.params[:action].try(:titleize)}" ] }
  #config.included_models = [Kit, KitItem, User, Zone, Sector, Center, ProgramType, Venue, Permission, Role]
  config.included_models = [AccessPrivilege, Kit, KitItem, KitItemName, Teacher, User, Zone, Sector, Venue, Center, ProgramType, Permission, Role, Pincode]
  #config.authorize_with :cancan
  config.audit_with :history, User
  config.actions do
    # root actions
    dashboard                     # mandatory
    # collection actions
    index                         # mandatory
    new  do
      except [Role]
    end
    export
    history_index
    bulk_delete
    # member actions
    show
    edit
    delete do
      except [Role]
    end
    history_show
   # show_in_app
    # import actions using external gem rails_admin_import
    #import
  end

end
