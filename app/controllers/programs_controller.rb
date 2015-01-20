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
        @programs = Program.where("center_id IN (?) AND (end_date > ? OR state NOT IN (?))", center_ids, (Time.zone.now - 1.month.from_now), ::Program::FINAL_STATES).order('end_date DESC')
        format.html # index.html.erb
        format.json { render json: @programs }
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

    if @program.residential?
      # perform validations for attr_accessor
      @program.errors[:first_day_timing_id] << "required. Please select start timing for first day." if not params[:program].has_key?(:first_day_timing_id)
      @program.errors[:last_day_timing_id] << "required. Please select end timing for last day." if not params[:program].has_key?(:last_day_timing_id)
      # initialize timing_ids
      @program.timing_ids = Timing.pluck(:id)
    end

    respond_to do |format|
      if not @program.errors.empty?
        format.html { render action: "new" }
        format.json { render json: @program.errors, status: :unprocessable_entity }
      else
        if @program.can_create?
          if @program.send(::Program::EVENT_PROPOSE) && @program.save
            # initialize program date timings
            self.update_date_timings!(params)
            format.html { redirect_to @program, :notice => 'Program created successfully' }
          else
            load_centers_program_type_timings!(Center.find(params[:program][:center_id].to_i),
                                               ProgramDonation.find(params[:program][:program_donation_id].to_i))
            format.html { render action: "new" }
            format.json { render json: @program.errors, status: :unprocessable_entity }
          end
        else
          format.html { redirect_to programs_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
          format.json { render json: @program.errors, status: :unprocessable_entity }
        end
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
      if params.has_key?(start_time)
        time = Time.zone.parse(params[start_time])
        # normalize the timings - this is same as the remove_date HACK in timing model
        @program.session_time[:start][i-1] = time.change(:month => 1, :day => 1, :year => 2000)
      end
      end_time = "end_time_#{i.to_s}".to_sym
      if params.has_key?(end_time)
        time = Time.zone.parse(params[end_time])
        # normalize the timings - this is same as the remove_date HACK in timing model
        @program.session_time[:end][i-1] = time.change(:month => 1, :day => 1, :year => 2000)
      end
      intro_start_time = "intro_start_time_#{i.to_s}".to_sym
      if params.has_key?(intro_start_time)
        time = Time.zone.parse(params[intro_start_time])
        # normalize the timings - this is same as the remove_date HACK in timing model
        @program.intro_time[:start][i-1] = time.change(:month => 1, :day => 1, :year => 2000)
      end
      intro_end_time = "intro_end_time_#{i.to_s}".to_sym
      if params.has_key?(intro_end_time)
        time = Time.zone.parse(params[intro_end_time])
        # normalize the timings - this is same as the remove_date HACK in timing model
        @program.intro_time[:end][i-1] = time.change(:month => 1, :day => 1, :year => 2000)
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
    @selected_program_donation = program_donation = ProgramDonation.find(params[:program_donation_id])
    # map to name and id for use in our options_for_select
    @disable_create_button = true
    self.hide_intro_first_last_day_timings(false, program_donation)
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
      self.hide_intro_first_last_day_timings(true)
    else
      timings =  program_donations[0].program_type.timings
      self.hide_intro_first_last_day_timings(false, program_donations[0])
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

  def load_centers_program_type_timings!(selected_center = nil, selected_program_donation = nil)
    center_ids = current_user.accessible_center_ids(:center_scheduler)
    @centers = Center.where("id IN (?)", center_ids).order('name ASC')
    @selected_center = selected_center.blank? ? @centers[0] : selected_center
    @program_donations = @selected_center.program_donations.sort_by{|pd| pd[:name]}
    if @program_donations.empty?
      @selected_program_donation = ['None Available']
      @timings = []
      @disable_create_button = true
      self.hide_intro_first_last_day_timings(true)
    else
      @selected_program_donation = selected_program_donation.blank? ? @program_donations[0] : selected_program_donation
      @timings = @selected_program_donation.program_type.timings.sort_by{|t| t[:start_time]}
      @disable_create_button = false
      self.hide_intro_first_last_day_timings(false, @selected_program_donation)
    end
  end

  def update_date_timings!(params)
    # mark day_timing_ids for different program types
    program_type = @program.program_donation.program_type
    day_timing_ids = []
    full_day_timing_ids = Timing.pluck(:id)
    for i in 1..program_type.no_of_days
      if @program.residential?
        if i != 1 and i != program_type.no_of_days
          dt_ids = full_day_timing_ids
        else
          if i == 1
            id = params[:program][:first_day_timing_id].to_i
            dt_ids = Array(id..Timing.pluck(:id).last)
          elsif i == program_type.no_of_days
            id = params[:program][:last_day_timing_id].to_i
            dt_ids = Array(Timing.pluck(:id).first..id)
          end
        end
      else
        if @program.has_intro? and i == 1
          # remove nil values using compact
          dt_ids = params[:program][:intro_timing_ids].map {|s| s.to_i unless s.blank?}.compact
        elsif program_type.has_full_day? and program_type.full_days.include?(i)
          dt_ids = full_day_timing_ids
        else
          dt_ids = @program.timing_ids
        end
      end
      day_timing_ids << dt_ids
    end

    # create the date timings for the day_timing_ids above
    date_timings = []
    day_offset = 0
    day_timing_ids.each { |dt|
      date = @program.start_date.to_date + day_offset.day
      dt.each { |t|
        # double check - create only if timing_id is there
        date_timings << DateTiming.where(:date => @program.start_date + day_offset.day, :timing_id => t).first_or_create unless t.blank?
      }
      day_offset = day_offset + 1
    }
    # update data timings
    @program.update_attributes :date_timings => date_timings

    # update start and end date time
    @program.update_attributes :start_date => @program.start_date_time, :end_date => @program.end_date_time

    # update timing_str string
    if @program.residential?
      # If residential, e.g., for BSP --
      # "Starts on 2nd at 2:00pm. Ends on 6th by 6:00pm"
      timing_str = "Starts on #{@program.start_date.day.ordinalize} at #{@program.start_date.strftime("%-I:%M%P")}. Ends on #{@program.end_date.day.ordinalize} by #{@program.end_date.strftime("%-I:%M%P")}."
    else
      if @program.has_intro?
        # If intro e.g, IE --
        # "(Intro) Morning (6am - 10am), Night(6pm - 10pm); (Session) Morning (6am - 10am), Afternoon (10am - 2pm), Night (6pm - 10pm)"
        timing_str = "[Intro] " + (@program.intro_timings.map {|c| c[:name]}).join(", ") + "; [Session] " + (@program.timings.map {|c| c[:name]}).join(", ")
      else
        # If no intro e.g, Uyir Nokkam --
        # "Morning (6am - 10am), Afternoon (10am - 2pm), Evening (2pm - 6pm), Night (6pm - 10pm)"
        timing_str = (@program.timings.map {|c| c[:name]}).join(", ")
      end
    end
    @program.update_attributes :timing_str => timing_str

  end


  def hide_intro_first_last_day_timings(flag, program_donation = nil)
    if flag
      @hide_intro_timings = @hide_first_day_timing = @hide_last_day_timing = true
      @hide_timings = false
    else
      @hide_intro_timings = (program_donation.program_type.has_intro? == false)
      @hide_first_day_timing = (program_donation.program_type.residential? == false)
      @hide_last_day_timing = (program_donation.program_type.residential? == false)
      @hide_timings = (program_donation.program_type.residential? == true)
    end
  end

  private

  def state_update(prog, trig)
    if Program::PROCESSABLE_EVENTS.include?(trig)
      prog.send(trig)
    end
  end


end
