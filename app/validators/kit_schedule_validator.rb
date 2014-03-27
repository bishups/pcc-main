# To change this template, choose Tools | Templates
# and open the template in the editor.

class KitScheduleValidator < ActiveModel::Validator
  def validate(record)

    if record.program_id.nil?
      return
    end  
    if !Program.exists?(record.program_id)
      record.errors[:program_id] << " --- Mentioned Program does not exist"
      return
    end

    if ::KitSchedule.where(['start_date >= ? AND start_date <= ? AND kit_id = ? and id != ? and state != ?', 
      record.start_date-1, record.end_date+1, record.kit_id, record.id,'cancel' ] ).count() > 0
      record.errors[:start_date] << " -- Kit is Already assigned For the Date"

    elsif ::KitSchedule.where(['end_date >= ? AND end_date <= ? AND kit_id = ? and id != ? and state != ?', 
      record.start_date-1, record.end_date+1,record.kit_id,record.id,'cancel']).count() > 0
      record.errors[:end_date] << " -- Already Kit is assigned for given date range"
    end
    if record.start_date < Date.today
      record.errors[:start_date] << "cannot be in the past"
    elsif record.end_date < record.start_date
      record.errors[:end_date] << "cannot be before start date"
    end

    if record.id.nil?
      if ::KitSchedule.where( ['program_id = ? AND state != ?',record.program_id,'cancel'] ).count() > 0
        record.errors[:program_id] << "- Kit is Already assigned for the program"
      end
     else
      if ::KitSchedule.where( ['program_id = ? AND state != ? AND id != ?',record.program_id,'cancel',record.id] ).count() > 0
        record.errors[:program_id] << "- Kit is Already assigned for the program"
      end
     end 

    if record.state == 'unavailable'
      if record.comments.nil?
        record.errors[:comments] << "Cannot be Left blank To make a Kit unavailable"
      end
    end

    kit = Kit.find(record.kit_id)
    if kit.state != ::Kit::AVAILABLE.to_s
      record.errors[:kit_id] << "Kit state is #{kit.state} , cannot be blocked until Available"
    end

    program_center = Program.find(record.program_id).center
    if program_center.id != kit.center.id
      record.errors[:center] << "-- Kit Can only be blocked for Center #{kit.center.name}"
    end

  end
end
