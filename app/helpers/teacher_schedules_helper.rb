module TeacherSchedulesHelper


  def teacher_schedule_state_tag(ts)

    proc do
      # TODO - change this once state machine is added to teacher schedule
      if ts.state == ::Ontology::Teacher::STATE_AVAILABLE  #ts.available?
        '<span class="label label-info">Available</span>'
      elsif ts.state == ::Ontology::Teacher::STATE_BLOCKED  #ts.blocked?
        '<span class="label label-danger">Blocked</span>'
      elsif ts.state == ::Ontology::Teacher::STATE_ASSIGNED  #ts.assigned?
        '<span class="label label-success">Assigned</span>'
      elsif ts.state == ::Ontology::Teacher::STATE_UNAVAILABLE  #ts.unavailable?
        '<span class="label label-default">unavailable</span>'
      else
        ""
      end
    end.call().html_safe
  end

end
