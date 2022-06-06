class Api::AppointmentsController < ApplicationController
  def index
    # TODO: return all values

    appointments = []

    # using .includes to avoid n+1 queries
    @appointments = Appointment.includes(:patient).includes(:doctor)

    @appointments.each do |a| 
        appointments.push({
          id: a.id,
          patient: { name: a.patient.name },
          doctor: { name: a.doctor.name, id: a.doctor.id },
          created_at: a.created_at,
          start_time: a.start_time,
          duration_in_minutes: a.duration_in_minutes
        })
    end

    render json: appointments

    # TODO: return filtered values
  end

  def create
    # TODO:
  end
end
