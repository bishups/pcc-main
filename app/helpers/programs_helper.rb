module ProgramsHelper
  def program_state_tag(prog)
    proc do
      if prog.state == ::Program::STATE_PROPOSED
        '<span class="label label-warning">Proposed</span>'
      elsif prog.state == ::Program::STATE_ANNOUNCED
        '<span class="label label-success">Announced</span>'
      elsif prog.state == ::Program::STATE_REGISTRATION_OPEN
        '<span class="label label-success">Registration Open</span>'
      elsif prog.state == ::Program::STATE_CANCELLED
        '<span class="label label-danger">Cancelled</span>'
      elsif prog.state == ::Program::STATE_IN_PROGRESS
        '<span class="label label-info">In-Progress</span>'
      elsif prog.state == ::Program::STATE_CONDUCTED
        '<span class="label label-info">Conducted</span>'
      elsif prog.state == ::Program::STATE_CLOSED
        '<span class="label label-info">Closed</span>'
      else
        '<span class="label label-default">Unknown</span>'
      end
    end.call().html_safe
  end
end

