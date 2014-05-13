class VenueScheduleValidator < ActiveModel::Validator
  def validate(record)
    return false if record.program.nil?

    program = record.program
    current_date = Time.zone.now
    if program.start_date < current_date && !program.in_progress?
      record.errors[:start_date] << " cannot be in the past"
    elsif program.end_date < current_date
      record.errors[:end_date] << " cannot be in the past"
    elsif program.end_date < program.start_date
      record.errors[:end_date] << " cannot be before start date"
    elsif VenueSchedule.overlapping(record).count() > 0
        record.errors[:start_date] << "timing overlaps with existing schedule."
    end
  end
end