class VenueSchedulesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_venue!

  def index
    @venue_schedules = @venue.venue_schedules.where(['start_date > ?', DateTime.now])

    respond_to do |format|
      format.html
      format.json { render json: @venue_schedules }
    end
  end

  def new
    @venue_schedule = @venue.venue_schedules.new

    respond_to do |format|
      format.html
      format.json { render json: @venue_schedule }
    end
  end

  def create
    @venue_schedule = @venue.venue_schedules.new(params[:venue_schedule])
    @venue_schedule.reserving_user_id = current_user.id
    @venue_schedule.setup_details!

    respond_to do |format|
      if @venue_schedule.save
        format.html { redirect_to [@venue, @venue_schedule], notice: 'Venue Schedule was successfully created.' }
        format.json { render json: @venue_schedule, status: :created, location: @venue_schedule }
      else
        format.html { render action: "new" }
        format.json { render json: @venue_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    @venue_schedule = @venue.venue_schedules.find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: @venue_schedule }
    end
  end

  def edit
    @venue_schedule = @venue.venue_schedules.find(params[:id])
    @trigger = params[:trigger]

    respond_to do |format|
      format.html
      format.json { render json: @venue_schedule }
    end
  end

  def update
    @venue_schedule = @venue.venue_schedules.find(params[:id])
    @trigger = params[:trigger]

    state_update(@venue_schedule, @trigger)

    respond_to do |format|
      format.html
      format.json { render :json => @venue_schedule }
    end
  end

  def destroy
  end

  private

  def load_venue!
    @venue = ::Venue.find(params[:venue_id].to_i)
  end

  def state_update(vs, trig)
    if ::VenueSchedule::PROCESSABLE_EVENTS.include?(@trigger)
      vs.send(trig.to_sym)
    end
  end

end
