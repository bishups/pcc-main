# create geo_graphical_locations`
workbook = RubyXL::Parser.parse("/Users/senthil/Downloads/Uyir Nokkam Centers list - Ver 2.0.xlsx")
["West","South","East","north"].each do |zone_name|
sheet=workbook[zone_name].get_table
  sheet[:table].each do |row|

    ####### Creating or Finding a Zone #######
    puts "Processing zone --> #{row['Zone']} "
    zone=Zone.find_or_initialize_by_name(row["Zone"])
    if not zone.save
      puts "Zone #{zone.name} has not been saved because of  #{zone.errors.messages}"
    end

    ####### Creating or Finding a Sector #######
    sector_name = row['Current Sector name'] || row['Current Sector Name']
    puts "Processing sector --> #{sector_name} "
    sector=Sector.find_or_initialize_by_name(sector_name.strip) if sector_name
    sector.zone = zone
    if not sector.save
      puts "Sector #{sector.name} has not been saved because of  #{sector.errors.messages}"
    end

    ####### Creating or Finding a Center #######
    center_name = row['Current centre name'] || row['Current Centre Name']
    puts "Processing center --> #{center_name}"
    center=Center.find_or_initialize_by_name(center_name.strip) if center_name
    center.sector = sector
    if not center.save
      puts "Center #{center.name} has not been saved because of  #{center.errors.messages}"
    end
  end
end