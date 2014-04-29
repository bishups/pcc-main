class ProgramValidator < ActiveModel::Validator
  def validate(record)
    if record.start_date == Time.zone.now.to_date
      record.errors[:start_date] << " cannot be today's date"
      return false
    end

    if record.start_date < Time.zone.now.to_date
      record.errors[:start_date] << " cannot be in the past"
      return false
    end

    if record.end_date < record.start_date
      record.errors[:end_date] << " cannot be before start date"
      return false
    end

    return true
  end
end