class ProgramDatatable < AjaxDatatablesRails::Base
  def_delegators :@view, :program_state_tag, :link_to, :program_path

  def initialize(view)
    @view = view
  end

  # uncomment the appropriate paginator module,
  # depending on gems available in your project.
   include AjaxDatatablesRails::Extensions::Kaminari
  # include AjaxDatatablesRails::Extensions::WillPaginate
  # include AjaxDatatablesRails::Extensions::SimplePaginator

  def sortable_columns
    # list columns inside the Array in string dot notation.
    # Example: 'users.email'
    @sortable_columns ||= [ programs.id, programs.pid, programs.locality_name, programs.start_date,  programs.end_date,  programs.state]
  end

  def searchable_columns
    # list columns inside the Array in string dot notation.
    # Example: 'users.email'
    @searchable_columns ||=  []# [ programs.id, programs.pid, programs.locality_name, programs.start_date,  programs.end_date,  programs.state]
  end

  def as_json(options = {})
    {
        sEcho: params[:sEcho].to_i,
        iTotalRecords: Program.count,
        iTotalDisplayRecords: programs.total_entries,
        aaData: data
    }
  end

  private

  def data
    programs.map do |program|
      [
        # comma separated list of the values for each cell of a table row
        # example: record.attribute,
          program.id,
          program.pid,
          program.locality_name,
          program.program_donation.name,
          program.start_date.strftime('%d %B %Y'),
          program.end_date.strftime('%d %B %Y'),
          program.display_timings,
          program_state_tag(program),
          program.can_view? ? link_to("Open", program_path(program), :class => 'btn btn-primary btn-sm') : ""
      ]
    end
  end

  def get_raw_records
    # in_geography = (current_user.is? :any, :in_group => [:geography])
    # center_ids = (in_geography) ? current_user.accessible_center_ids : []
    # Program.where("center_id IN (?) AND state NOT IN (?)", center_ids, ::Program::FINAL_STATES).order('end_date DESC')
    Program.where("state NOT IN (?)", ::Program::FINAL_STATES)
  end

  def programs
    @programs ||= fetch_programs
  end

  def fetch_programs
    programs = Program.order("#{sort_column} #{sort_direction}")
    programs = programs.page(page).per_page(per_page)
    # if params[:sSearch].present?
    #   programs = programs.where("name like :search or category like :search", search: "%#{params[:sSearch]}%")
    # end
    programs
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[id pid start_date end_date]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end


  # ==== Insert 'presenter'-like methods below if necessary
end
