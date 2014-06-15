module TeacherSchedulesHelper


  def teacher_schedule_state_tag(ts)

    proc do
      case ts.state
      when ::TeacherSchedule::STATE_AVAILABLE
        '<span class="label label-info">Available</span>'
      when ::TeacherSchedule::STATE_UNAVAILABLE
        '<span class="label label-default">Not Available</span>'
      when ::TeacherSchedule::STATE_AVAILABLE_EXPIRED
        '<span class="label label-danger">Available (Expired)</span>'
      when ::TeacherSchedule::STATE_ACTIVITY
        '<span class="label label-success">Activity</span>'
      when ::TeacherSchedule::STATE_RESERVED
        '<span class="label label-warning">Reserved</span>'
      when ::TeacherSchedule::STATE_BREAK
        '<span class="label label-danger">Break</span>'
      when ::TeacherSchedule::STATE_TRAVEL
        '<span class="label label-warning">Travel</span>'
      else
        program_teacher_schedule_state_tag(ts)
      end
    end.call().html_safe
  end

end
