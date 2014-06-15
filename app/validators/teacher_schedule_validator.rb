class TeacherScheduleValidator < ActiveModel::Validator
  def validate(record)
    validate_dates(record)
    if record.teacher.full_time?
      record.errors[:base] << "Dates overlap existing schedule" if record.schedule_overlaps?
    else
      validate_schedule_overlap(record)
    end
  end

  # Validator
  def validate_dates(record)
    current_date = Time.zone.now.to_date
    if record.start_date.nil?
      # the error string will be returned from other validations
    elsif record.start_date == current_date
      record.errors[:start_date] << " cannot be today's date"
    elsif record.start_date < current_date
      record.errors.add(:start_date, " cannot be in past")
    elsif record.start_date > record.end_date
      record.errors.add(:end_date, "cannot be less than start date")
    end
  end

  def validate_schedule_overlap(record)
    # teacher schedule should not overlap with any existing schedule
    ts = TeacherSchedule.where(['(start_date BETWEEN ? AND ?) AND timing_id = ? AND teacher_id = ?',
                                record.start_date, record.end_date, record.timing_id, record.teacher_id]).to_a
    if !ts.empty? && (ts.count > 1 || ts[0].id != record.id)
      record.errors[:start_date] << " timing overlaps with existing schedule."
      return
    end

    ts = TeacherSchedule.where(['(end_date BETWEEN ? AND ?) AND timing_id = ? AND teacher_id = ?',
                                record.start_date, record.end_date, record.timing_id, record.teacher_id]).to_a
    if !ts.empty? && (ts.count > 1 || ts[0].id != record.id)
      record.errors[:end_date] << " timing overlaps with existing schedule."
      return
    end

    ts = TeacherSchedule.where(['start_date <= ? AND end_date >= ? AND timing_id = ? AND teacher_id = ?',
                                record.start_date, record.end_date, record.timing_id, record.teacher_id]).to_a
    if !ts.empty? && (ts.count > 1 || ts[0].id != record.id)
      record.errors[:start_date] << " timing overlaps with existing schedule."
      return
    end
  end

end