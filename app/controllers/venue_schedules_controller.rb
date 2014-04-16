class VenueSchedulesController < ApplicationController
  before_filter :authenticate_user!
  #before_filter :load_venue!


  # GET /venue_schedules
  # GET /venue_schedules.json
  def index
    @venue = ::Venue.find(params[:venue_id].to_i)
    @venue_schedules = @venue.venue_schedules.joins(:program).where(['programs.start_date > ?', Time.zone.now])

    respond_to do |format|
      format.html
      format.json { render json: @venue_schedules }
    end
  end

  # GET /venue_schedules/new
  # GET /venue_schedules/new.json
  def new
    @venue = ::Venue.find(params[:venue_id].to_i) if params.has_key?(:venue_id)
    @venue_schedule = VenueSchedule.new

    @venue_schedule.program_id = params[:program_id] if params.has_key?(:program_id)
    @venue_schedule.venue_id = params[:venue_id] if params.has_key?(:venue_id)

    respond_to do |format|
      format.html
      format.json { render json: @venue_schedule }
    end
  end

  # POST /venue_schedules
  # POST /venue_schedules.json
  def create
    # TODO - fix this hack to initialize @venue on create from fix _form.html.erb to pass correct params :-(
    if params.has_key?(:venue_id)
      venue_id = params[:venue_id].to_i
    elsif params.has_key?(:venue_schedule)
      venue_id = (params[:venue_schedule][:venue_id]).to_i  if params[:venue_schedule].has_key?(:venue_id)
    end

    @venue = ::Venue.find(venue_id)

    @venue_schedule = VenueSchedule.new(params[:venue_schedule])
    @venue_schedule.venue_id = @venue.id

    @venue_schedule.blocked_by_user_id = current_user.id
    #@venue_schedule.setup_details!

    respond_to do |format|
      if @venue_schedule.save
        format.html { redirect_to @venue_schedule, notice: 'Venue Schedule was successfully created.' }
        format.json { render json: @venue_schedule, status: :created, location: @venue_schedule }
      else
        format.html { render action: "new" }
        format.json { render json: @venue_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /venue_schedules/1
  # GET /venue_schedules/1.json
  def show
    @venue_schedule = ::VenueSchedule.find(params[:id].to_i)

    respond_to do |format|
      format.html
      format.json { render json: @venue_schedule }
    end
  end

  # GET /venue_schedules/1/edit
  def edit
    @venue_schedule = ::VenueSchedule.find(params[:id].to_i)
    @trigger = params[:trigger]
    #authorize! :update, @venue
    respond_to do |format|
      format.html
      format.json { render json: @venue_schedule }
    end
  end

  # PUT /venue_schedules/1
  # PUT /venue_schedules/1.json
  def update
    @venue_schedule =::VenueSchedule.find(params[:id].to_i)
    @trigger = params[:trigger]
    #authorize! :update, @venue
    @venue_schedule.blocked_for = params[:blocked_for] if params.has_key?(:blocked_for)

    respond_to do |format|
      format.html do
        if state_update(@venue_schedule, @trigger)
          if @venue_schedule.save!
            #redirect_to action: "edit" , :trigger => params[:trigger]
            redirect_to [@venue,@venue_schedule]
          end
        else
          render :action => 'edit'
        end
      end
      format.json { render :json => @venue_schedule }
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
