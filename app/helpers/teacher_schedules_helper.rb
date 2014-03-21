module TeacherSchedulesHelper
	def self.combine_consecutive_schedules(ts)
		teacher_schedule = TeacherSchedule.where(['end_date = ? AND slot = ? AND user_id = ?', ts.start_date - 1.day, ts.slot, ts.user_id]).first

		if (teacher_schedule != nil)
			ts.start_date = teacher_schedule.start_date
		end

		teacher_schedule = TeacherSchedule.where(['start_date = ? AND slot = ? AND user_id = ?', ts.end_date + 1.day, ts.slot, ts.user_id]).first

		if (teacher_schedule != nil)
			ts.end_date = teacher_schedule.end_date
		end

		return ts
	end

end
