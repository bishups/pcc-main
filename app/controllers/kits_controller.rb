class KitsController < ApplicationController
  # GET /kits
  # GET /kits.json
  def index
    @kits = Kit.all

    @kits.each do |kit|
      @kit_schedules = kit.kit_schedules.where("start_date <= ? and end_date >= ?", Time.now, Time.now).order(:start_date)

      if( @kit_schedules.nil? || @kit_schedules.empty? )
        kit.state = "available"
      else
        kit.state = @kit_schedules.first.state
       end    
    end



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

    respond_to do |format|
      if @kit.update_attributes(params[:kit])
        format.html { redirect_to @kit, notice: 'Kit was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @kit.errors, status: :unprocessable_entity }
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
end
