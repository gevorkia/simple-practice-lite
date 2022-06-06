class Api::AppointmentsController < ApplicationController
  def index

    @appointments = []
    @past         = params[:past]

    # using .includes to avoid n+1 queries
    appointments = Appointment.includes(:patient).includes(:doctor)

    if  @past == '1'
      appointments = appointments.where("start_time < ?", Time.zone.now)
    elsif @past == '0'
      appointments = appointments.where("start_time > ?", Time.zone.now)
    elsif params[:length] && params[:page]

      @apts_per_page = params[:length].to_i
      @page = params[:page].to_i

      if (@apts_per_page < 1 || @page < 1 )
        render json: {status: "error", code: 422, message: "Query parameters must be greater than 0."}
        return
      else
        appointments = Appointment.offset((@page - 1) * @apts_per_page).limit(@apts_per_page)      
      end
    end

    appointments.each do |a| 
        @appointments.push({
          id: a.id,
          patient: { name: a.patient.name },
          doctor: { name: a.doctor.name, id: a.doctor.id },
          created_at: a.created_at,
          start_time: a.start_time,
          duration_in_minutes: a.duration_in_minutes
        })
    end

    render json: @appointments

  end

  def create
    # TODO:
  end
end
