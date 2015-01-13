class DateTiming < ActiveRecord::Base
  has_and_belongs_to_many :programs, :join_table => :programs_date_timings
  attr_accessible :program_ids, :programs

end

