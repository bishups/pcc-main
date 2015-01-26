class CreateProgramsDateTimings < ActiveRecord::Migration
  def up
    create_table :programs_date_timings do |t|
      t.belongs_to  :program
      t.belongs_to  :date_timing
    end
#    Program.all.each do |program|
#      day_timing_ids = []
#      for i in 1..program.program_donation.program_type.no_of_days
#        day_timing_ids << program.timing_ids
#      end
#      date_timings = []
#      day_offset = 0
#      day_timing_ids.each { |dt|
#        date = program.start_date.to_date + day_offset.day
#        dt.each { |t|
#         # double check - create only if timing_id is there
#          next if t.blank?
#          date_timings << DateTiming.where(:date => date, :timing_id => t).first_or_create
#          puts "program # #{program.id}:: adding date_time :: #{date} - #{t}"
#        }
#        day_offset = day_offset + 1
#      }
#      # update data timings
#      program.update_attributes :date_timings => date_timings
#    end
  end
  def down
  end
end
