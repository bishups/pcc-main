class TravelTicketsController < ApplicationController

    def index

      @travel_tickets = TravelTicket.all
      t= 1


    end

    def new
      @travel_ticket = TravelTicket.new
      if(@travel_ticket.is_pcc_travel_vendor?)
      @travel_ticket.pcc_travel_request_id=params[:pcc_travel_request]
      else

        format.html { redirect_to travel_tickets_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @travel_tickets.errors, status: :unprocessable_entity }

      end
    end

    def create
      @travel_ticket = TravelTicket.new(params[:travel_ticket])

      if @travel_ticket.save
        @travel_ticket.pcc_travel_request_id=@travel_ticket.name
        @pcc_travel_request=PccTravelRequest.find(@travel_ticket.pcc_travel_request_id)
        @pcc_travel_request.state='ticket uploaded'
        @pcc_travel_request.save
        requester=@pcc_travel_request.requester

            UserMailer.email(@pcc_travel_request, requester, 'booked', 'ticket uploaded', '', 'You can download the ticket from the link mentioned below').deliver
            UserMailer.sms(@pcc_travel_request, requester, 'booked', 'ticket uploaded', '', 'You can download the ticket from the link mentioned below').deliver

        respond_to do |format|
        format.html { redirect_to pcc_travel_requests_path, notice: 'Travel Ticket was successfully uploaded.' }
        end
      else
        render "new"
      end
    end

    def show
      @travel_ticket = TravelTicket.find(params[:id])

      if(@travel_ticket.is_pcc_travel_vendor?)
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @travel_ticket }
      end
      else

        format.html { redirect_to root_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @pcc_travel_requests.errors, status: :unprocessable_entity }

      end
    end


    def destroy
      @travel_ticket = TravelTicket.find(params[:id])
      if(@travel_ticket.is_pcc_travel_vendor?)
      @travel_ticket.destroy
      redirect_to travel_tickets_path, notice:  "The travel ticket #{@travel_ticket.name} has been deleted."
      else

        format.html { redirect_to root_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @pcc_travel_requests.errors, status: :unprocessable_entity }

      end
    end


    private
    def travel_ticket_params
      params.require(:travel_ticket).permit(:name, :attachment)
    end
  end
