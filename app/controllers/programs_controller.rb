class ProgramsController < ApplicationController
  before_filter :authenticate_user!

  def index

    in_geography = (current_user.is? :any, :in_group => [:geography])
    center_ids = (in_geography) ? current_user.accessible_center_ids : []
    respond_to do |format|
      if center_ids.empty?
        @programs = []
        format.html { redirect_to root_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @programs, status: :unprocessable_entity }
      else
#        @programs = Program.where("center_id IN (?) AND (end_date > ? OR state NOT IN (?))", center_ids, (Time.zone.now - 1.month.from_now), ::Program::FINAL_STATES).order('end_date DESC')
        format.html # index.html.erb
#        format.json { render json: @programs }
        format.json { render json: ProgramDatatable.new(view_context) }
      end
    end
  end

  def new
    @program = Program.new
    @program.current_user = current_user

    load_centers_program_type_timings!
    respond_to do |format|
      if @program.can_create? :any => true
        format.html # new.html.erb
        format.json { render json: @program }
      else
        format.html { redirect_to programs_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @program.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    @program = Program.find(params[:id].to_i)
    @program.current_user = current_user

    respond_to do |format|
      if @program.can_view?
        format.html # show.html.erb
        format.json { render json: @program }
      else
        format.html { redirect_to programs_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @program.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    @program = Program.new(params[:program])
    @program.current_user = current_user
    @program.proposer_id = current_user.id
    # Also update the start_date and end_date to start_date_time and end_date_time

    respond_to do |format|
      if @program.can_create?
        if @program.send(::Venue::EVENT_PROPOSE) && @program.save
          @program.update_attributes :start_date => @program.start_date_time, :end_date => @program.end_date_time
          format.html { redirect_to @program, :notice => 'Program created successfully' }
        else
          load_centers_program_type_timings!
          format.html { render action: "new" }
          format.json { render json: @program.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to programs_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @program.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @program = Program.find(params[:id])
    @program.current_user = current_user
    @trigger = params[:trigger]
    @program.comment_category = Comment.where('model = ? AND action = ?', 'Program', @trigger).pluck(:text)

    if !@program.can_update?
      respond_to do |format|
        format.html { redirect_to program_path(@program), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @program.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @program = Program.find(params[:id])
    @program.dummy_init_time
    @program.current_user = current_user
    @trigger = params[:trigger]
    @program.feedback = params[:feedback] if params.has_key?(:feedback)
    @program.capacity = params[:capacity] if params.has_key?(:capacity)
    @program.announced_locality = params[:announced_locality] if params.has_key?(:announced_locality)
    @program.contact_phone = params[:contact_phone] if params.has_key?(:contact_phone)
    @program.contact_email = params[:contact_email] if params.has_key?(:contact_email)

    for i in 1..Timing.all.count
      start_time = "start_time_#{i.to_s}".to_sym
      end_time = "end_time_#{i.to_s}".to_sym
      if params.has_key?(start_time)
        time = Time.zone.parse(params[start_time])
        # normalize the timings - this is same as the remove_date HACK in timing model
        @program.time[:start][i-1] = time.change(:month => 1, :day => 1, :year => 2000)
      end
      if params.has_key?(end_time)
        time = Time.zone.parse(params[end_time])
        # normalize the timings - this is same as the remove_date HACK in timing model
        @program.time[:end][i-1] = time.change(:month => 1, :day => 1, :year => 2000)
      end
    end

    @program.load_comments!(params)

    respond_to do |format|
      if @program.can_update?
        if state_update(@program, @trigger) &&  @program.save!
          format.html { redirect_to @program, notice: 'Program was successfully updated.' }
          format.json { render json: @program }
        else
          format.html { render :action => 'edit' }
          format.json { render json: @program.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to program_path(@program), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @program.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
  end

  def update_timings
    # updates timings based on selection
    program_donation = ProgramDonation.find(params[:program_donation_id])
    # map to name and id for use in our options_for_select
    @disable_create_button = true
    timings = program_donation.program_type.timings.sort_by{|t| t[:start_time]}
    unless timings.empty?
      @timings = timings.map{|a| [a.name, a.id]}
      @disable_create_button = false
    end
  end

  def update_program_donations
   # @program_donations = center.program_donations.sort_by{|pd| pd[:name]}.map{|a| [a.name, a.id]}
    # updates program donation based on selection
    center = Center.find(params[:center_id].to_i)
    # map to name and id for use in our options_for_select
    program_donations = center.program_donations.sort_by{|pd| pd[:name]}
    if program_donations.empty?
      @program_donations = ['None Available']
      @timings = ['None Available']
      @disable_create_button = true
    else
      timings =  program_donations[0].program_type.timings
      if timings.empty?
        @disable_create_button = true
      else
        @disable_create_button = false
        @timings = timings.sort_by{|t| t[:start_time]}.map{|a| [a.name, a.id]}
      end
      @program_donations = program_donations.map{|a| [a.name, a.id]}
    end
    @selected_program_donation = @program_donations[0]
  end

  def load_centers_program_type_timings!
    center_ids = current_user.accessible_center_ids(:center_scheduler)
    @centers = Center.where("id IN (?)", center_ids).order('name ASC')
    @selected_center = @centers[0]
    @program_donations = @selected_center.program_donations.sort_by{|pd| pd[:name]}
    if @program_donations.empty?
      @selected_program_donation = ['None Available']
      @timings = []
      @disable_create_button = true
    else
      @selected_program_donation = @program_donations[0]
      @timings =  @selected_program_donation.program_type.timings.sort_by{|t| t[:start_time]}
      @disable_create_button = false
    end
  end




  private

  def state_update(prog, trig)
    if Program::PROCESSABLE_EVENTS.include?(trig)
      prog.send(trig)
    end
  end





end
