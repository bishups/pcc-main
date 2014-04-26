class VenueScheduleValidator < ActiveModel::Validator
  def validate(record)
    return if record.program.nil?

    program = record.program

    if program.start_date < Time.zone.now
      record.errors[:start_date] << "cannot be in the past"
    elsif program.end_date < program.start_date
      record.errors[:end_date] << "cannot be before start date"
    elsif VenueSchedule.overlapping(record).count() > 0
        record.errors[:start_date] << "timing overlaps with existing schedule."
    end
  end
end