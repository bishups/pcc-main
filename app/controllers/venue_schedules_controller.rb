class VenueSchedulesController < ApplicationController
  before_filter :authenticate_user!
  #before_filter :load_venue!


  # GET /venue_schedules
  # GET /venue_schedules.json
  def index
    @venue = ::Venue.find(params[:venue_id].to_i)
    @venue.current_user = current_user
    @venue_schedules = @venue.venue_schedules.joins(:program).where(['programs.end_date > ? OR venue_schedules.state NOT IN (?) ', (Time.zone.now - 1.month.from_now), ::VenueSchedule::FINAL_STATES]).order('programs.start_date ASC')

    respond_to do |format|
      if @venue.can_view_schedule?
        format.html
        format.json { render json: @venue_schedules }
      else
        format.html { redirect_to @venue, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @venue.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /venue_schedules/new
  # GET /venue_schedules/new.json
  def new
    @venue = ::Venue.find(params[:venue_id].to_i) if params.has_key?(:venue_id)
    @venue_schedule = VenueSchedule.new
    @venue_schedule.current_user = current_user

    if params.has_key?(:venue_id)
      @venue_schedule.venue_id = params[:venue_id]
      center_ids = @venue_schedule.venue.center_ids
    end

    if params.has_key?(:program_id)
      @venue_schedule.program_id = params[:program_id]
      center_ids = @venue_schedule.program.center_id
    end

    respond_to do |format|
      if @venue_schedule.can_create?(center_ids)
        format.html
        format.json { render json: @venue_schedule }
      else
        if @venue_schedule.venue_id.nil?
          format.html { redirect_to program_path(params[:program_id]), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        else
          format.html { redirect_to venue_schedules_path(:venue_id => @venue), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        end
        format.json { render json: @venue_schedule.errors, status: :unprocessable_entity }
      end
    end
  end


  # POST /venue_schedules
  # POST /venue_schedules.json
  def create
    # HACK - to initialize @venue on create from fix _form.html.erb to pass correct params :-(
    if params.has_key?(:venue_id)
      venue_id = params[:venue_id].to_i
    elsif params.has_key?(:venue_schedule)
      venue_id = (params[:venue_schedule][:venue_id]).to_i  if params[:venue_schedule].has_key?(:venue_id)
    end

    @venue = ::Venue.find(venue_id)

    @venue_schedule = VenueSchedule.new(params[:venue_schedule])
    @venue_schedule.current_user = current_user
    @venue_schedule.venue_id = @venue.id

    @venue_schedule.blocked_by_user_id = current_user.id
    #@venue_schedule.setup_details!

    respond_to do |format|
      if @venue_schedule.can_create?
        if @venue_schedule.send(::VenueSchedule::EVENT_BLOCK_REQUEST) && @venue_schedule.save
          format.html { redirect_to @venue_schedule, notice: 'Venue Schedule was successfully created.' }
          format.json { render json: @venue_schedule, status: :created, location: @venue_schedule }
        else
          format.html { render action: "new" }
          format.json { render json: @venue_schedule.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to venue_schedules_path(:venue_id => @venue), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @venue_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /venue_schedules/1
  # GET /venue_schedules/1.json
  def show
    @venue_schedule = ::VenueSchedule.find(params[:id].to_i)
    @venue_schedule.current_user = current_user

    respond_to do |format|
      if @venue_schedule.can_update?
        format.html
        format.json { render json: @venue_schedule }
      else
        format.html { redirect_to venue_schedules_path(:venue_id => @venue_schedule.venue), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @venue_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /venue_schedules/1/edit
  def edit
    @venue_schedule = ::VenueSchedule.find(params[:id].to_i)
    @venue_schedule.current_user = current_user
    @trigger = params[:trigger]
    @venue_schedule.comment_category = Comment.where('model IS ? AND action IS ?', 'VenueSchedule', @trigger).pluck(:text)
    #authorize! :update, @venue
    respond_to do |format|
      if @venue_schedule.can_update?
        format.html
        format.json { render json: @venue_schedule }
      else
        format.html { redirect_to venue_schedules_path(:venue_id => @venue_schedule.venue), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @venue_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /venue_schedules/1
  # PUT /venue_schedules/1.json
  def update
    @venue_schedule =::VenueSchedule.find(params[:id].to_i)
    @venue_schedule.current_user = current_user
    @trigger = params[:trigger]
    #authorize! :update, @venue
    @venue_schedule.block_expiry_date = params[:block_expiry_date] if params.has_key?(:block_expiry_date)
    @venue_schedule.load_comments!(params)

    respond_to do |format|
      if @venue_schedule.can_update?
        if state_update(@venue_schedule, @trigger) &&  @venue_schedule.save!
          format.html { redirect_to [@venue, @venue_schedule], notice: 'Venue Schedule was successfully updated.' }
          format.json { render :json => @venue_schedule }
        else
          format.html { render :action => 'edit' }
          format.json { render json: @venue_schedule.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to venue_schedules_path(:venue_id => @venue_schedule.venue), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @venue_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /venue_schedules/1
  # DELETE /venue_schedules/1.json
  def destroy
  end

  private

  #def load_venue!
  #  @venue = ::Venue.find(params[:venue_id].to_i)
  #  redirect_to venue_path(@venue) unless @venue.published?
  #end

  def state_update(vs, trig)
    if ::VenueSchedule::PROCESSABLE_EVENTS.include?(trig)
      vs.send(trig)
    end
  end

end
