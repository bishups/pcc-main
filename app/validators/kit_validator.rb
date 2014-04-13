class KitValidator < ActiveModel::Validator
    def validate(record)
      if record.state == ::Kit::STATE_UNDER_REPAIR
        assigned_kit_schedules = record.kit_schedules.where("state NOT IN (?)",['blocked','closed','cancel'])
        if( !assigned_kit_schedules.nil? && assigned_kit_schedules.count > 0 )
          record.errors[:state] << "Cannot be Left blank To make a Kit unavailable"
          return false
        end
        if record.condition_comments.nil?
          record.errors[:condition_comments] << "Cannot be Left blank To make a Kit unavailable"
          return false
        end
      end

      if record.state == "unavailable"
        assigned_kit_schedules = record.kit_schedules.where("state NOT IN (?)",['blocked','closed','cancel'])
        if( !assigned_kit_schedules.nil? && assigned_kit_schedules.count > 0 )
          record.errors[:state] << "Cannot be Left blank To make a Kit unavailable"
          return false
        end
        if record.general_comments.nil?
          record.errors[:general_comments] << "Cannot be Left blank To make a Kit unavailable"
          return false
        end
      end
    end
end