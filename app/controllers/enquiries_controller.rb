class EnquiriesController < ApplicationController
  # GET /enquiries
  # GET /enquiries.json
  def index
    @enquiries = Enquiry.order('updated_at DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @enquiries }
    end
  end

  # GET /enquiries/1
  # GET /enquiries/1.json
  def show
    @enquiry = Enquiry.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @enquiry }
    end
  end

  # GET /enquiries/new
  # GET /enquiries/new.json
  def new
    @enquiry = Enquiry.new

    if user_signed_in?
      @enquiry.name = current_user.fullname()
      @enquiry.email = current_user.email
      @enquiry.phone = current_user.phone
      @enquiry.mobile = current_user.mobile
    end

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @enquiry }
    end
  end

  # GET /enquiries/1/edit
  def edit
    @enquiry = Enquiry.find(params[:id])
  end

  # POST /enquiries
  # POST /enquiries.json
  def create
    @enquiry = Enquiry.new(params[:enquiry])

    respond_to do |format|
      if @enquiry.save
        format.html { redirect_to @enquiry, notice: 'Enquiry was successfully created.' }
        format.json { render json: @enquiry, status: :created, location: @enquiry }
      else
        format.html { render action: "new" }
        format.json { render json: @enquiry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /enquiries/1
  # PUT /enquiries/1.json
  def update
    @enquiry = Enquiry.find(params[:id])

    respond_to do |format|
      if @enquiry.update_attributes(params[:enquiry])
        format.html { redirect_to @enquiry, notice: 'Enquiry was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @enquiry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /enquiries/1
  # DELETE /enquiries/1.json
  def destroy
    @enquiry = Enquiry.find(params[:id])
    @enquiry.destroy

    respond_to do |format|
      format.html { redirect_to enquiries_url }
      format.json { head :no_content }
    end
  end
end
