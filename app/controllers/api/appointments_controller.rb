class Api::AppointmentsController < ApplicationController
  def index

    @appointments = []
    @past         = params[:past]

    # using .includes to avoid n+1 queries
    appointments = Appointment.includes(:patient).includes(:doctor)

    if  @past == '1'
      appointments = appointments.where("start_time < NOW()")
    elsif @past == '0'
      appointments = appointments.where("start_time > NOW()")
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
    @start_time    = appointment_params[:start_time]   

    # confirm whether patient exists
    @patient  = Patient.find_by(name: @patient_name)

    if @patient
      # check for existing appointments. 
      # the following can be simplified with correct datetime conversion in query to correctly return identical appointment, then checking for that appointment in line 63
      @patient_apts = Appointment.where(patient_id: @patient.id).where(doctor_id: @doctor_id)

      @existing_apt = false
      @patient_apts.each do |a|
      if a.start_time.to_i === @start_time.to_datetime.to_i
        @existing_apt = true
      end
    end

      if @existing_apt
        render json: {status: "error", code: 422, message: 'An appointment already exists at that time for this patient'}
        return
      end
    else
      Patient.create!(
        doctor_id:  @doctor_id,
        name:       @patient_name
      )

      @patient  = Patient.find_by(name: @patient_name)
    end  

    @appointment = Appointment.create!(
      patient_id: @patient.id,
      doctor_id:  @doctor_id,
      start_time: @start_time,
      duration_in_minutes: 50
    )

    if @appointment.save
      @doctor = Doctor.find_by(id: @doctor_id)
    
      @formatted_appointment = 
      {
        id: @appointment.id,
        patient: { name: @patient.name },
        doctor: { name: @doctor.name, id: @doctor_id },
        created_at: @appointment.created_at,
        start_time: @appointment.start_time,
        duration_in_minutes: @appointment.duration_in_minutes
      }
      render json: @formatted_appointment
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
