module TeachersHelper

  def teacher_state_tag(t)
    proc do
      case t.state
        when ::Teacher::STATE_ATTACHED
          '<span class="label label-success">Attached</span>'
        when ::Teacher::STATE_UNFIT
          '<span class="label label-danger">Not Fit</span>'
        when ::Teacher::STATE_UNATTACHED
          '<span class="label label-default">Not Attached</span>'
        else
          '<span class="label label-default">Unknown</span>'
      end
    end.call().html_safe
  end
end
