class ChangeSuggestionsController < ApplicationController
  # GET /change_suggestions
  # GET /change_suggestions.json
  def index
    @change_suggestions = ChangeSuggestion.find_all_by_pcc_communication_request_id(params[:id])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @change_suggestions }
    end
  end

  # GET /change_suggestions/1
  # GET /change_suggestions/1.json
  def show
    @change_suggestion = ChangeSuggestion.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @change_suggestion }
    end
  end

  # GET /change_suggestions/new
  # GET /change_suggestions/new.json
  def new
    @change_suggestion = ChangeSuggestion.new
    @change_suggestion.pcc_communication_request_id=params[:id]
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @change_suggestion }
    end
  end

  # GET /change_suggestions/1/edit
  def edit
    @change_suggestion = ChangeSuggestion.find(params[:id])
  end

  # POST /change_suggestions
  # POST /change_suggestions.json
  def create
    @change_suggestion = ChangeSuggestion.new(params[:change_suggestion])

    respond_to do |format|
      if @change_suggestion.save
        format.html { redirect_to @change_suggestion, notice: 'Change suggestion was successfully created.' }
        format.json { render json: @change_suggestion, status: :created, location: @change_suggestion }
      else
        format.html { render action: "new" }
        format.json { render json: @change_suggestion.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /change_suggestions/1
  # PUT /change_suggestions/1.json
  def update
    @change_suggestion = ChangeSuggestion.find(params[:id])

    respond_to do |format|
      if @change_suggestion.update_attributes(params[:change_suggestion])
        format.html { redirect_to @change_suggestion, notice: 'Change suggestion was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @change_suggestion.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /change_suggestions/1
  # DELETE /change_suggestions/1.json
  def destroy
    @change_suggestion = ChangeSuggestion.find(params[:id])
    @change_suggestion.destroy

    respond_to do |format|
      format.html { redirect_to change_suggestions_url }
      format.json { head :no_content }
    end
  end
end
