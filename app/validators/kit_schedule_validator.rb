# To change this template, choose Tools | Templates
# and open the template in the editor.

class KitScheduleValidator < ActiveModel::Validator
  def validate(record)

    if record.program_id.nil?
      return
    end  

    if ::KitSchedule.where(['start_date >= ? AND start_date <= ? AND kit_id = ? and id != ? and state != ?', 
      record.start_date-1, record.end_date+1, record.kit_id, record.id,'cancelled' ] ).count() > 0
      record.errors[:start_date] << " -- Kit is Already assigned For the Date"

    elsif ::KitSchedule.where(['end_date >= ? AND end_date <= ? AND kit_id = ? and id != ? and state != ?', 
      record.start_date-1, record.end_date+1,record.kit_id,record.id,'cancelled']).count() > 0
      record.errors[:end_date] << " -- Already Kit is assigned for given date range"
    end
    if record.start_date < Date.today
      record.errors[:start_date] << "cannot be in the past"
    elsif record.end_date < record.start_date
      record.errors[:end_date] << "cannot be before start date"
    end

    if record.state == 'unavailable'
      if record.comments.nil?
        record.errors[:comments] << "Cannot be Left blank To make a Kit unavailable"
      end
    end
  end
end
