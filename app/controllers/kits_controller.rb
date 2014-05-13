class KitsController < ApplicationController
  # GET /kits
  # GET /kits.json
  before_filter :authenticate_user!
  def index

    in_geography = (current_user.is? :any, :in_group => [:geography])
    center_ids = in_geography ? current_user.accessible_center_ids : []
    respond_to do |format|
      if center_ids.empty?
        @kits = []
        format.html { redirect_to root_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @kits, status: :unprocessable_entity }
      else
        @kits = Kit.joins("JOIN centers_kits ON centers_kits.kit_id = kits.id").where('centers_kits.center_id IN (?)', center_ids).uniq.all
        format.html # index.html.erb
        format.json { render json: @kits }
      end
    end
  end

  # GET /kits/1
  # GET /kits/1.json
  def show
    @kit = Kit.find(params[:id])
    @kit.current_user = current_user

    respond_to do |format|
      if @kit.can_view?
        format.html # show.html.erb
        format.json { render json: @kit }
      else
        format.html { redirect_to kits_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @kit.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /kits/new
  # GET /kits/new.json
  def new
    @kit = Kit.new
    @kit.current_user = current_user

    respond_to do |format|
      if @kit.can_create? :any => true
        format.html # new.html.erb
        format.json { render json: @kit }
      else
        format.html { redirect_to kits_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @kit.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /kits/1/edit
  def edit
    @kit = Kit.find(params[:id])
    @kit.current_user = current_user
    @trigger = params[:trigger]

    respond_to do |format|
      if @kit.can_update?
        format.html
        format.json { render json: @kit }
      else
        format.html { redirect_to kits_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @kit.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /kits
  # POST /kits.json
  def create
    @kit = Kit.new(params[:kit])
    @kit.current_user = current_user

    respond_to do |format|
      if @kit.can_create?
        if @kit.save
          format.html { redirect_to @kit, notice: 'Kit was successfully created.' }
          format.json { render json: @kit, status: :created, location: @kit }
        else
          format.html { render action: "new" }
          format.json { render json: @kit.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to kits_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @kit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /kits/1
  # PUT /kits/1.json
  def update
    @kit = Kit.find(params[:id])
    @kit.current_user = current_user
    @trigger = params[:trigger]
    @kit.comments = params[:comments]

    respond_to do |format|
      if @kit.can_update?
        if state_update(@kit, @trigger) &&  @kit.save!
          format.html { redirect_to @kit, notice: 'Kit was successfully updated.' }
          format.json { render :json => @kit }
        else
          format.html { render :action => 'edit' }
          format.json { render json: @kit.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to kits_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @kit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /kits/1
  # DELETE /kits/1.json
  def destroy
    # cannot delete kit for now
=begin
    @kit = Kit.find(params[:id])
    @kit.current_user = current_user
    @kit.destroy

    respond_to do |format|
      format.html { redirect_to kits_url }
      format.json { head :no_content }
    end
=end
  end

  def state_update(kit, trig)
    if ::Kit::PROCESSABLE_EVENTS.include?(trig)
      kit.send(trig)
    end
  end

end
