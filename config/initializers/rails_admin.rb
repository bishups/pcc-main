RailsAdmin.config do |config|
  # or somethig more dynamic
  config.main_app_name = Proc.new { |controller| [ "PCC", "Administration BackOffice - #{controller.params[:action].try(:titleize)}" ] }
  config.included_models = [Zone,Sector,Center,ProgramType]
  #config.authorize_with :cancan
  config.audit_with :history, User
  config.actions do
    # root actions
    dashboard                     # mandatory
    # collection actions
    index                         # mandatory
    new
    export
    history_index
    bulk_delete
    # member actions
    show
    edit
    delete
    history_show
    show_in_app
    # import actions using external gem rails_admin_import
    #import
  end

end