module ProgramsHelper
  def program_state_tag(prog)
    proc do
      if prog.program_announcement_view?
        if [::Program::STATE_ANNOUNCED, ::Program::STATE_REGISTRATION_CLOSED].include?(prog.state)
          '<span class="label label-success">Announced</span>'
        elsif [::Program::STATE_IN_PROGRESS].include?(prog.state)
          '<span class="label label-info">In-Progress</span>'
        elsif [::Program::STATE_CANCELLED].include?(prog.state)
          '<span class="label label-danger">Cancelled</span>'
        elsif [::Program::STATE_CONDUCTED, ::Program::STATE_TEACHER_CLOSED, ::Program::STATE_ZAO_CLOSED, ::Program::STATE_CLOSED].include?(prog.state)
          '<span class="label label-default">Closed</span>'
        else
          '<span class="label label-default">Unknown</span>'
        end
      else
        if prog.state == ::Program::STATE_PROPOSED
          '<span class="label label-warning">Proposed</span>'
        elsif prog.state == ::Program::STATE_ANNOUNCED
          '<span class="label label-success">Announced</span>'
        elsif prog.state == ::Program::STATE_CANCELLED
          '<span class="label label-danger">Cancelled</span>'
        elsif prog.state == ::Program::STATE_REGISTRATION_CLOSED
          '<span class="label label-warning">Registration Closed</span>'
        elsif prog.state == ::Program::STATE_IN_PROGRESS
          '<span class="label label-info">In-Progress</span>'
        elsif prog.state == ::Program::STATE_CONDUCTED
          '<span class="label label-info">Conducted</span>'
        elsif prog.state == ::Program::STATE_CLOSED
          '<span class="label label-default">Closed</span>'
        elsif prog.state == ::Program::STATE_DROPPED
          '<span class="label label-default">Dropped</span>'
        elsif prog.state == ::Program::STATE_TEACHER_CLOSED
          '<span class="label label-warning">Teacher Closed</span>'
        elsif prog.state == ::Program::STATE_ZAO_CLOSED
          '<span class="label label-info">ZAO Closed</span>'
        elsif prog.state == ::Program::STATE_EXPIRED
          '<span class="label label-danger">Expired</span>'
        else
          '<span class="label label-default">Unknown</span>'
        end
      end
    end.call().html_safe
  end
end
