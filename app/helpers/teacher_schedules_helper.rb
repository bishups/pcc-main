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
      else
        program_teacher_schedule_state_tag(ts)
      end
    end.call().html_safe
  end

end
