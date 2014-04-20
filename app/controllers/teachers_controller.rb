class TeachersController < ApplicationController

  before_filter :authenticate_user!


  # GET /teachers
  # GET /teachers.json
  def index
    @teachers = Teacher.all   # TODO: Filter by role

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @teachers }
    end
  end

  # GET /teachers/1
  # GET /teachers/1.json
  def show
    @teacher = Teacher.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @teacher }
    end
  end

  # GET /teachers/new
  # GET /teachers/new.json
  def new
    @teacher = Teacher.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @teacher }
    end
  end

  # GET /teachers/1/edit
  def edit
    if flash[:teacher]
      @teacher = flash[:teacher]
    else
      @teacher = Teacher.find(params[:id])
    end
    @trigger = params[:trigger]
  end

  # POST /teachers
  # POST /teachers.json
  def create
    @teacher = Teacher.new(params[:teacher])
    @teacher.current_user = current_user

    respond_to do |format|
      if @teacher.save
        format.html { redirect_to @teacher, notice: 'Teacher was successfully created.' }
        format.json { render json: @teacher, status: :created, location: @teacher }
      else
        format.html { render action: "new" }
        format.json { render json: @teacher.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /teachers/1
  # PUT /teachers/1.json
  def update
    @teacher = Teacher.find(params[:id])
    @trigger = params[:trigger]
    @teacher.comments = params[:comments] if params.has_key?(:comments)

    state_update(@teacher, @trigger)
    respond_to do |format|
      format.html do
        if @teacher.errors.empty? && @teacher.save!
          redirect_to [@teacher]
          #format.html { redirect_to @teacher, notice: 'Teacher was successfully updated.' }
          #format.json { head :no_content }
        else
          #format.html { render action: "edit" }
          #format.json { render json: @teacher.errors, status: :unprocessable_entity }
          flash[:teacher] = @teacher
          redirect_to :action => :edit, :trigger => params[:trigger]
        end
      end
    end

  end


  # DELETE /teachers/1
  # DELETE /teachers/1.json
  def destroy
    @teacher = Teacher.find(params[:id])
    @teacher.destroy

    respond_to do |format|
      format.html { redirect_to teachers_url }
      format.json { head :no_content }
    end
  end

  private

  def state_update(ts, trig)
    ts.current_user = current_user
    if ::Teacher::PROCESSABLE_EVENTS.include?(@trigger)
      ts.send(trig)
    end
  end
end
