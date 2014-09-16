class PccCommunicationRequestsController < ApplicationController
  # GET /pcc_communication_requests
  # GET /pcc_communication_requests.json
  before_filter :authenticate_user!
  def index
    @pcc_communication_requests = PccCommunicationRequest.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @pcc_communication_requests }
    end
  end

  # GET /pcc_communication_requests/1
  # GET /pcc_communication_requests/1.json
  def show
    @pcc_communication_request = PccCommunicationRequest.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @pcc_communication_request }
    end
  end

  # GET /pcc_communication_requests/new
  # GET /pcc_communication_requests/new.json
  def new
    @pcc_communication_request = PccCommunicationRequest.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @pcc_communication_request }
    end
  end

  # GET /pcc_communication_requests/1/edit
  def edit
    @pcc_communication_request = PccCommunicationRequest.find(params[:id])
  end

  # POST /pcc_communication_requests
  # POST /pcc_communication_requests.json
  def create
    @pcc_communication_request = PccCommunicationRequest.new(params[:pcc_communication_request])
    @pcc_communication_request.requester=current_user
    respond_to do |format|
      if @pcc_communication_request.save
        format.html { redirect_to @pcc_communication_request, notice: 'Pcc communication request was successfully created.' }
        format.json { render json: @pcc_communication_request, status: :created, location: @pcc_communication_request }
      else
        format.html { render action: "new" }
        format.json { render json: @pcc_communication_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /pcc_communication_requests/1
  # PUT /pcc_communication_requests/1.json
  def update
    @pcc_communication_request = PccCommunicationRequest.find(params[:id])

    respond_to do |format|
      if @pcc_communication_request.update_attributes(params[:pcc_communication_request])
        format.html { redirect_to @pcc_communication_request, notice: 'Pcc communication request was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @pcc_communication_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pcc_communication_requests/1
  # DELETE /pcc_communication_requests/1.json
  def destroy
    @pcc_communication_request = PccCommunicationRequest.find(params[:id])
    @pcc_communication_request.destroy

    respond_to do |format|
      format.html { redirect_to pcc_communication_requests_url }
      format.json { head :no_content }
    end
  end
end
