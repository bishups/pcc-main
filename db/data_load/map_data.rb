## Script to map the data after the schema change done by Anuj.


## There is no state called "UNFIT", changing those to not attached and removing zones and centers assosiated with that. 

Teacher.where({:state=>"Not Fit"}).each do |teacher|
 comments = "#{teacher.additional_comments} Teacher Marked As Unfit." 
 teacher.state = 'Not Attached'
 teacher.additional_comments = comments
 teacher.zones=[]
 teacher.centers=[]  
end

## Initiaising role as main teacher, if there is no role

TeacherSchedule.update_all("role = '#{TeacherSchedule::ROLE_MAIN_TEACHER}'","role is null")


#Chaning timing to match new values.

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


