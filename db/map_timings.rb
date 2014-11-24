
timing_mapping = {
    "Morning (6am-9am)" => ["Morning (6am-10am)", "2000-01-01 06:00", "2000-01-01 10:00" ],
    "Afternoon (10am-1pm)" => [ "Afternoon (10am-2pm)", "2000-01-01 10:00", "2000-01-01 14:00" ],
    "Evening (2pm-5pm)" => ["Evening (2pm-6pm)","2000-01-01 14:00","2000-01-01 18:00"],
    "Night (6pm-9pm)" => ["Night (6pm-10pm)", "2000-01-01 18:00", "2000-01-01 22:00"]
}

timing_mapping.each do |old_timing,new_timing|
  t=Timing.find_by_name(old_timing)
  puts "Process timing #{t.name}" if t
  t.name = new_timing[0]
  t.start_time = new_timing[1]
  t.end_time = new_timing[2]
  t.save
end
