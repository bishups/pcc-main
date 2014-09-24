# create pincodes
workbook = RubyXL::Parser.parse("pincode.xlsx")
sheet=workbook["Pincode"].get_table
sheet[:table].each do |row|
  puts  row["Pincode"]
  puts   row["Location"]
  debugger
  pincode = Pincode.new(:pincode => row["Pincode"].to_i, :location_name => row["Location"] )
  if not pincode.save
    puts "Error in saving pincode #{pincode.errors.messages}"
  end

end


timing_mapping = {

   "Morning (6am-9am)" => {:name => "Morning (6am-10am)", :start_time => "6am", :end_time => "10am" },
   "Afternoon (10am-1pm)" => {:name => "Afternoon (10am-2pm)", :start_time => "10am", :end_time => "2pm"},
   "Evening (2pm-5pm)" => {:name => "Evening (2pm-6pm)", :start_time => "2pm", :end_time => "6pm"},
   "Night (6pm-9pm)" => {:name => "Night (6pm-10pm)", :start_time => "6pm", :end_time => "10pm"}

}

timing_mapping.each do |old_name,new_timing|
  t=Timing.find_or_initialize_by_name(old_name)
  t.attributes=(new_timing)
  if not t.save
    puts "Timing #{t.name} has not been saved because of #{t.errors.messages}"
  end
end
