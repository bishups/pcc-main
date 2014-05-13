class ProgramValidator < ActiveModel::Validator
  def validate(record)
    current_date = Time.zone.now.to_date
    if record.start_date.nil?
      # don't return any string here, it will be return by later validate
    elsif record.start_date == current_date
      record.errors[:start_date] << " cannot be today's date"
    elsif record.start_date < current_date
      record.errors[:start_date] << " cannot be in the past"
    elsif record.end_date < record.start_date
      record.errors[:end_date] << " cannot be before start date"
    end
  end
end