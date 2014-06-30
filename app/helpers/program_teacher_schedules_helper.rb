module ProgramTeacherSchedulesHelper

  def program_teacher_schedule_state_tag(pts)
    proc do
      if pts.state == ::ProgramTeacherSchedule::STATE_BLOCKED
        '<span class="label label-danger">Blocked</span>'
      elsif pts.state == ::ProgramTeacherSchedule::STATE_ASSIGNED
        '<span class="label label-success">Assigned</span>'
      elsif pts.state == ::ProgramTeacherSchedule::STATE_RELEASE_REQUESTED
        '<span class="label label-warning">Release Requested</span>'
      elsif pts.state == ::ProgramTeacherSchedule::STATE_IN_CLASS
        '<span class="label label-info">In Class</span>'
      elsif pts.state == ::ProgramTeacherSchedule::STATE_COMPLETED_CLASS
        '<span class="label label-default">Completed Class</span>'
      else
        '<span class="label label-default">Unknown</span>'
      end
    end.call().html_safe
  end
end
