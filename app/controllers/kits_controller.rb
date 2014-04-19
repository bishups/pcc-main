class KitsController < ApplicationController
  # GET /kits
  # GET /kits.json
  before_filter :authenticate_user!
  def index
    @kits = Kit.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @kits }
    end
  end

  # GET /kits/1
  # GET /kits/1.json
  def show
    @kit = Kit.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @kit }
    end
  end

  # GET /kits/new
  # GET /kits/new.json
  def new
    @kit = Kit.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @kit }
    end
  end

  # GET /kits/1/edit
  def edit
    @kit = Kit.find(params[:id])
        @trigger = params[:trigger]

  end

  # POST /kits
  # POST /kits.json
  def create
    @kit = Kit.new(params[:kit])

    respond_to do |format|
      if @kit.save
        format.html { redirect_to @kit, notice: 'Kit was successfully created.' }
        format.json { render json: @kit, status: :created, location: @kit }
      else
        format.html { render action: "new" }
        format.json { render json: @kit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /kits/1
  # PUT /kits/1.json
  def update
    @kit = Kit.find(params[:id])
    @trigger = params[:trigger]
    @kit.condition_comments = params[:condition_comments]

    respond_to do |format|
      format.html do
        if state_update(@kit, @trigger)
          if @kit.save!
            #redirect_to action: "edit" , :trigger => params[:trigger]
            redirect_to [@kit]
          end
        else
            render :action => 'edit'
        end
      end
    end
  end

  # DELETE /kits/1
  # DELETE /kits/1.json
  def destroy
    @kit = Kit.find(params[:id])
    @kit.destroy

    respond_to do |format|
      format.html { redirect_to kits_url }
      format.json { head :no_content }
    end
  end

  def state_update(kit, trig)
    if ::Kit::PROCESSABLE_EVENTS.include?(trig)
      kit.send(trig)
    end
  end
end
