# create geo_graphical_locations
workbook = RubyXL::Parser.parse("/Users/senthil/Downloads/Chennai-zone-sector-center.xlsx")
sheet=workbook["Centre-Sector-Zone"].get_table
sheet[:table].each do |row|

  ####### Creating or Finding a Zone #######

  zone=Zone.find_or_create_by_name(row["Zone"])

  ####### Creating or Finding a Sector #######

  sector=Sector.find_or_create_by_name_and_zone_id(row["Current Sector name"].strip,zone.id)

  ####### Creating or Finding a Center #######

  center=Center.find_or_create_by_name_and_sector_id(row["Current centre name"].strip,sector.id)
  center.pincodes.build(:pincode => row["Pincode"],:location_name => row["Isha Center"])

end