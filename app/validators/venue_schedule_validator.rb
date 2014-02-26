class VenueScheduleValidator < ActiveModel::Validator
  def validate(record)
    return if record.program.nil?

    if ::VenueSchedule.where(['start_date >= ? AND start_date <= ? AND slot = ? AND id != ? AND state != ?', 
      record.start_date, record.end_date, record.slot, record.id, ::VenueSchedule::STATE_CANCELLED]).count() > 0
      record.errors[:start_date] << "overlaps with existing schedule."
    elsif ::VenueSchedule.where(['end_date >= ? AND end_date <= ? AND slot = ? AND id != ? AND state != ?', 
      record.start_date, record.end_date, record.slot, record.id, ::VenueSchedule::STATE_CANCELLED]).count() > 0
      record.errors[:end_date] << "overlaps with existing schedule."
    elsif ::VenueSchedule.where(['start_date >= ? AND start_date <= ? AND slot = ? AND id != ? and state != ?', 
      record.start_date, record.end_date, ::Ontology::Venue::SLOT_FULL_DAY, record.id, ::VenueSchedule::STATE_CANCELLED]).count() > 0
      record.errors[:start_date] << "overlaps with existing schedule."
    elsif ::VenueSchedule.where(['end_date >= ? AND end_date <= ? AND slot = ? AND id != ? and state != ?', 
      record.start_date, record.end_date, ::Ontology::Venue::SLOT_FULL_DAY, record.id, ::VenueSchedule::STATE_CANCELLED]).count() > 0
      record.errors[:end_date] << "overlaps with existing schedule."
    end

    if record.start_date < Time.now
      record.errors[:start_date] << "cannot be in the past"
    elsif record.end_date < record.start_date
      record.errors[:end_date] << "cannot be before start date"
    end
  end
end