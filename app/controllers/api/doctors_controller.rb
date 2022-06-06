class Api::DoctorsController < ApplicationController
  def index
    # return doctors without appointments
    @doctors = Doctor.where.not(id: Appointment.pluck(:doctor_id).uniq)

    render json: @doctors
  end
end