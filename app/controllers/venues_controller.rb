class VenuesController < ApplicationController
  before_filter :authenticate_user!

  # GET /venues
  # GET /venues.json
  def index
    in_geography = (current_user.is? :any, :in_group => [:geography])
    in_finance = (current_user.is? :any, :in_group => [:finance])
    center_ids = (in_geography or in_finance) ? current_user.accessible_center_ids : []
    respond_to do |format|
      if center_ids.empty?
        @venues = []
        format.html { redirect_to root_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @venues, status: :unprocessable_entity }
      else
        @venues = Venue.joins("JOIN centers_venues ON centers_venues.venue_id = venues.id").where('centers_venues.center_id IN (?)', center_ids).uniq.all
        format.html # index.html.erb
        format.json { render json: @venues }
      end
    end
  end

  # GET /venues/1
  # GET /venues/1.json
  def show
    @venue = Venue.find(params[:id])
    @venue.current_user = current_user

    respond_to do |format|
      if @venue.can_view?
        format.html # show.html.erb
        format.json { render json: @venue }
      else
        format.html { redirect_to venues_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @venue.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /venues/new
  # GET /venues/new.json
  def new
    @venue = Venue.new
    @venue.current_user = current_user

    respond_to do |format|
      if @venue.can_create? :any => true
        format.html # new.html.erb
        format.json { render json: @venue }
      else
        format.html { redirect_to venues_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @venue.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /venues/1/edit
  def edit
    @venue = Venue.find(params[:id])
    @venue.current_user = current_user
    @trigger = params[:trigger]
    @venue.comment_category = Comment.where('model = ? AND action = ?', 'Venue', @trigger).pluck(:text)

    respond_to do |format|
      if @venue.can_update?
        format.html
        format.json { render json: @venue }
      else
        format.html { redirect_to venues_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @venue.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /venues
  # POST /venues.json
  def create
    @venue = Venue.new(params[:venue])
    @venue.current_user = current_user

    respond_to do |format|
      if @venue.can_create?
        if  @venue.save
          format.html { redirect_to @venue, notice: 'Venue was successfully created.' }
          format.json { render json: @venue, status: :created, location: @venue }
        else
          format.html { render action: "new" }
          format.json { render json: @venue.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to venues_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @venue.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /venues/1
  # PUT /venues/1.json
  def update
    @venue = Venue.find(params[:id])
    @venue.current_user = current_user
    @trigger = params[:trigger]
    @venue.load_comments!(params)

    respond_to do |format|
      if @venue.can_update?
        if state_update(@venue, @trigger) &&  @venue.save!
          format.html { redirect_to @venue, notice: 'Venue was successfully updated.' }
          format.json { render json: @venue }
         else
          format.html { render :action => 'edit' }
          format.json { render json: @venue.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to venues_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @venue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /venues/1
  # DELETE /venues/1.json
  def destroy
    # Cannot destroy a venue as of now
=begin
    @venue = Venue.find(params[:id])
    @venue.current_user = current_user
    @venue.destroy

    respond_to do |format|
      format.html { redirect_to venues_url }
      format.json { head :no_content }
    end
=end
  end

  private

  def state_update(vs, trig)
    if ::Venue::PROCESSABLE_EVENTS.include?(@trigger)
      vs.send(trig)
    end
  end


end
