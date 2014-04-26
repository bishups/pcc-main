module TeacherSchedulesHelper


  def teacher_schedule_state_tag(ts)

    proc do
      # TODO - change this once state machine is added to teacher schedule
      case ts.state
      when ::TeacherSchedule::STATE_AVAILABLE
        '<span class="label label-info">Available</span>'
      when ::ProgramTeacherSchedule::STATE_BLOCKED
        '<span class="label label-danger">Blocked</span>'
      when ::ProgramTeacherSchedule::STATE_ASSIGNED
        '<span class="label label-success">Assigned</span>'
      when ::TeacherSchedule::STATE_UNAVAILABLE
        '<span class="label label-default">Not Available</span>'
      else
        '<span class="label label-default">Unknown</span>'
      end
    end.call().html_safe
  end

end
