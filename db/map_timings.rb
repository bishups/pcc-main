timing_mapping = {
    "Morning (6am-9am)"    => ["Morning (6am-10am)", "2000-01-01 06:00", "2000-01-01 10:00"],
    "Afternoon (10am-1pm)" => ["Afternoon (10am-2pm)", "2000-01-01 10:00", "2000-01-01 14:00"],
    "Evening (2pm-5pm)"    => ["Evening (2pm-6pm)", "2000-01-01 14:00", "2000-01-01 18:00"],
    "Night (6pm-9pm)"      => ["Night (6pm-10pm)", "2000-01-01 18:00", "2000-01-01 22:00"]
}

timing_mapping.each do |old_timing, new_timing|
  t=Timing.find_by_name(old_timing)
  if t
    puts "Process timing #{t.name}"
    t.name       = new_timing[0]
    t.start_time = new_timing[1]
    t.end_time   = new_timing[2]
    unless t.save(:validate => false)
      puts "#{t.errors.messages}"
    end
  end
end



 { "Morning (6am-10am)" => "Morning (7 am to 9 am)",  "Evening (2pm-6pm)" => "Evening ( 6:30 pm to 8:30 pm)"}.each do | actual_timing, wrong_timing |
  wrong_timing_id=Timing.find_by_name(wrong_timing).id
  actual_timing_id=Timing.find_by_name(actual_timing).id
  sql = "update programs_timings set timing_id = #{actual_timing_id} where timing_id =#{wrong_timing_id}"
  result = ActiveRecord::Base.connection.execute(sql)
  puts result.inspect
  sql = "update teacher_schedules set timing_id = #{actual_timing_id} where timing_id =#{wrong_timing_id}"
  result = ActiveRecord::Base.connection.execute(sql)
  puts result.inspect
  sql = "update program_types_timings set timing_id = #{actual_timing_id} where timing_id =#{wrong_timing_id}"
  result = ActiveRecord::Base.connection.execute(sql)
  puts result.inspect
  Timing.find_by_name(wrong_timing).delete
end

