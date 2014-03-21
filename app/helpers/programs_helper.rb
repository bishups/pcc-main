module ProgramsHelper
  def program_state_tag(prog)
    proc do
      if prog.proposed?
        '<span class="label label-warning">Proposed</span>'
      elsif prog.announced?
        '<span class="label label-success">Announced</span>'
      elsif prog.registration_open?
        '<span class="label label-success">Registration Open</span>'
      elsif prog.cancelled?
        '<span class="label label-danger">Cancelled</span>'
      elsif prog.in_progress?
        '<span class="label label-info">In-Progress</span>'
      elsif prog.conducted?
        '<span class="label label-info">Conducted</span>'
      elsif prog.closed?
        '<span class="label label-info">Closed</span>'
      else
        '<span class="label label-default">Unknown</span>'
      end
    end.call().html_safe
  end
end
