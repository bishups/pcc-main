# create geo_graphical_locations
workbook = RubyXL::Parser.parse("master-data.xlsx")
sheet=workbook["Centre-Sector-Zone"].get_table
sheet[:table].each do |row|

  ####### Creating or Finding a Zone #######

  zone=Zone.find_or_create_by_name(row["Zone"])
  zonal_coordinator = User.find_or_initialize_by_email(row["Email Id  Isha Zonal Coordinator"].strip)
  if zonal_coordinator.new_record?
    zonal_coordinator.firstname =row["Name  Isha Zonal Coordinator"]
    zonal_coordinator.mobile=row["Contact No  Isha Zonal Coordinator"]
    zonal_coordinator.address = " "
    zonal_coordinator.access_privileges.build(:role=>Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:zonal_coordinator][:text]),:resource=>zone)
  elsif not zonal_coordinator.access_to_resource?(zone)
    zonal_coordinator.access_privileges.build(:role=>Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:zonal_coordinator][:text]),:resource=>zone)
  end
  zonal_coordinator.password = zonal_coordinator.firstname.squeeze.gsub(" ","_") if zonal_coordinator.firstname
  zonal_coordinator.password_confirmation = zonal_coordinator.firstname.squeeze.gsub(" ","_") if zonal_coordinator.firstname
  if not zonal_coordinator.save
    puts "Zonal cooridnator for #{zone.name} has not been saved because of  #{zonal_coordinator.errors.messages}"
  end
  ####### Creating or Finding a Sector #######

  sector=Sector.find_or_create_by_name_and_zone_id(row["Isha Sector"].strip,zone.id)
  sector_coordinator = User.find_or_initialize_by_email(row["Name - Isha Sector Coordinator"].downcase.squeeze.gsub(" ","-")+"@ishafoundation.org")
  if sector_coordinator.new_record?
    sector_coordinator.firstname= row["Name - Isha Sector Coordinator"]
    sector_coordinator.mobile= " "
    sector_coordinator.address = " "

    sector_coordinator.access_privileges.build(:role=>Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]),:resource=>sector)
  elsif not sector_coordinator.access_to_resource?(sector)
    sector_coordinator.access_privileges.build(:role=>Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:sector_coordinator][:text]),:resource=>sector)
  end
  sector_coordinator.password = sector_coordinator.firstname.squeeze.gsub(" ","_")  if sector_coordinator.firstname
  sector_coordinator.password_confirmation = sector_coordinator.firstname.squeeze.gsub(" ","_") if sector_coordinator.firstname
  if not sector_coordinator.save
    puts "Sector cooridnator for #{sector.name} has not been saved becuase of  #{sector_coordinator.errors.messages}"
  end

  ####### Creating or Finding a Center #######

  center=Center.find_or_create_by_name_and_sector_id(row["Isha Center"].strip,sector.id)
  center.pincodes.build(:pincode => row["Pincode"],:location_name => row["Isha Center"])
  center_coordinator = User.find_or_initialize_by_email(row["Email Id - Isha Center Coordinator"])
  if center_coordinator.new_record?
    center_coordinator.firstname= row["Name - Isha Center Coordinator"]
    center_coordinator.mobile= row["Contact No - Isha Center Coordinator"]
    center_coordinator.address = row["Address - Isha Center Coordinator"]
    center_coordinator.access_privileges.build(:role=>Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:center_coordinator][:text]),:resource=>center)
  elsif not center_coordinator.access_to_resource?(center)
    center_coordinator.access_privileges.build(:role=>Role.find_by_name(::User::ROLE_ACCESS_HIERARCHY[:center_coordinator][:text]),:resource=>center)
  end
  center_coordinator.password = center_coordinator.firstname.squeeze.gsub(" ","_")  if center_coordinator.firstname
  center_coordinator.password_confirmation = center_coordinator.firstname.squeeze.gsub(" ","_") if center_coordinator.firstname
  if not center_coordinator.save
    puts "Center cooridnator for #{center.name} has not been saved becuase of  #{center_coordinator.errors.messages}"
  end
end


##### Importing Teacher #####
workbook1 = RubyXL::Parser.parse("Teacher.xlsx")
sheet1=workbook1["PersonalDetails"].get_table
sheet1[:table].each do |row|
  teacher=Teacher.find_or_initialize_by_t_no(row["TraineeID"])
  if teacher.new_record?
    teacher.t_no = row["TraineeID"]
    teacher.state = Teacher::STATE_ATTACHED.to_s
    user=User.find_or_initialize_by_email(row["teacher_email_address"])
    if user.new_record?
      user.firstname=row["name"]
      user.address="#{row['teacher_addressline1']}\n#{row['teacher_addressline2']}"
      user.mobile=row["teacher_phoneno_mobile"]
      user.password= teacher.firstname.squeeze.gsub(" ","_")  if teacher.firstname
      user.password_confirmation = teacher.firstname.squeeze.gsub(" ","_") if teacher.firstname
    end
  elsif
  user = User.find_by_id(teacher.user_id)
  end
  teacher.user = user
  teacher.centers << Pincode.find_by_pincode(row["teacher_pincode"]).center
  teacher.zone = center.zone
  teacher.program_types << ProgramType.first
  if not teacher.save
    puts "Teacher #{user.firstname} has not been saved because of #{teacher.errors.messages}"
  end

end