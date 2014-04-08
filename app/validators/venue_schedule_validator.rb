class VenueScheduleValidator < ActiveModel::Validator
  def validate(record)
    return if record.program.nil?

    program = record.program

    if program.start_date < Time.now
      record.errors[:start_date] << "cannot be in the past"
    elsif program.end_date < program.start_date
      record.errors[:end_date] << "cannot be before start date"
    elsif
    #VenueSchedule.joins(:pricing_plans => {:subscriptions => :person}).where(:subscriptions => {:person_id => self})

    ""

      timing_ids = program.timing_ids.class == Array ? program.timing_ids : [program.timing_ids]
      if VenueSchedule.joins("JOIN programs ON programs.id = venue_schedules.program_id").joins("JOIN programs_timings ON programs.id = programs_timings.program_id").where(
          ['programs.id = programs_timings.program_id AND (programs.start_date BETWEEN ? AND ?) AND programs_timings.timing_id IN (?) AND venue_schedules.id != ? AND venue_schedules.state != ?',
                                program.start_date, program.end_date, timing_ids, record.id, ::VenueSchedule::STATE_CANCELLED]).count() > 0
        record.errors[:start_date] << "timing overlaps with existing schedule."
        return
      end
      if VenueSchedule.joins("JOIN programs ON programs.id = venue_schedules.program_id").joins("JOIN programs_timings ON programs.id = programs_timings.program_id").where(
          ['programs.id = programs_timings.program_id AND (programs.end_date BETWEEN ? AND ?) AND programs_timings.timing_id IN (?) AND venue_schedules.id != ? AND venue_schedules.state != ?',
           program.start_date, program.end_date, timing_ids, record.id, ::VenueSchedule::STATE_CANCELLED]).count() > 0
        record.errors[:end_date] << " timing overlaps with existing schedule."
        return
      end
      if VenueSchedule.joins("JOIN programs ON programs.id = venue_schedules.program_id").joins("JOIN programs_timings ON programs.id = programs_timings.program_id").where(
          ['programs.id = programs_timings.program_id AND (programs.start_date <= ? AND programs.end_date >= ?) AND programs_timings.timing_id IN (?) AND venue_schedules.id != ? AND venue_schedules.state != ?',
           program.start_date, program.end_date, timing_ids, record.id, ::VenueSchedule::STATE_CANCELLED]).count() > 0
        record.errors[:start_date] << " timing overlaps with existing schedule."
        return
      end
    end
  end
end