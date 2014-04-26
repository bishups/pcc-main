# To change this template, choose Tools | Templates
# and open the template in the editor.

class KitScheduleValidator < ActiveModel::Validator
  def validate(record)

    if record.start_date < -10.minutes.from_now
      record.errors[:start_date] << " for kit schedule cannot be in the past"
      return false
    end

    if record.end_date < record.start_date
      record.errors[:end_date] << " cannot be before start date"
      return false
    end

    if KitSchedule.overlapping_schedules(record).count() > 0
      record.errors[:base] << "Dates overlaps with existing schedule."
      return false
    end

=begin
    if KitSchedule.overlapping_reserves(record).count() > 0
      record.errors[:base] << "Dates overlaps with existing schedule."
      return false
    end

    if record.program.nil?
      if KitSchedule.overlapping_date_time_blocks(record, ::KitSchedule::FINAL_STATES).count() > 0
        record.errors[:base] << "Dates overlaps with existing schedule."
        return false
      end    else
      if KitSchedule.overlapping_blocks(record, ::KitSchedule::FINAL_STATES).count() > 0
       record.errors[:base] << "Dates overlaps with existing schedule."
        return false
      end
    end
=end
  end
end
