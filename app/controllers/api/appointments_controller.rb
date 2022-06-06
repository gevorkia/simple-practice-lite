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
    @patient_name  = appointment_params[:patient][:name]
    @doctor_id     = appointment_params[:doctor][:id]      

    @patient  = Patient.find_by(name: @patient_name)

    if !@patient
      Patient.create!(
        doctor_id:  @doctor_id,
        name:       @patient_name
      )

      @patient  = Patient.find_by(name: @patient_name)
    end

    @appointment = Appointment.create!(
      patient_id: @patient.id,
      doctor_id:  @doctor_id,
      start_time: appointment_params[:start_time],
      duration_in_minutes: 50
    )

    if @appointment.save
      render json: @appointment
    else
      render json: @appointment.errors.full_messages, status: 422
    end
  end

  private
  def appointment_params
    params[:appointment][:patient] = params[:patient]
    params[:appointment][:doctor] = params[:doctor]
    params.require(:appointment).permit(
        :start_time, 
        :duration_in_minutes,
        patient: [:name], 
        doctor: [:id], 
    )
  end
end
