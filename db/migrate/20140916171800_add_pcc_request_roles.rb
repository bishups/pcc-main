class AddPccRequestRoles < ActiveRecord::Migration
  def up
    permissions = [
        ["PCC Travel View", "read", "PccTravelRequest"],
        ["PCC Travel Management", "manage", "PccTravelRequest"],
        ["PCC Break View", "read", "PccBreakRequest"],
        ["PCC Break Management", "manage", "PccBreakRequest"]
    ]
    permissions.each do |p|
      Permission.create(:name=>p[0].to_s,:cancan_action=>p[1].to_s, :subject=>p[2].to_s)
    end

    roles={
        ::User::ROLE_ACCESS_HIERARCHY[:pcc_department][:text]  => ["PCC Travel View", "PCC Break View"],
        ::User::ROLE_ACCESS_HIERARCHY[:pcc_travel][:text]  => ["PCC Travel Management"],
        ::User::ROLE_ACCESS_HIERARCHY[:pcc_travel_approver][:text]  => ["PCC Travel Management"],
        ::User::ROLE_ACCESS_HIERARCHY[:pcc_travel_vendor][:text]  => ["PCC Travel Management"],
        ::User::ROLE_ACCESS_HIERARCHY[:pcc_break_approver][:text]  => ["PCC Break Management"],
    }
    roles.each do |name,permissions|
      Role.create(:name=>name.to_s,:permissions=>Permission.find_all_by_name(permissions))
    end
  end
end