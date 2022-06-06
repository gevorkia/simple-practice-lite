# TODO: Seed the database according to the following requirements:
# - There should be 10 Doctors with unique names
# - Each doctor should have 10 patients with unique names
# - Each patient should have 10 appointments (5 in the past, 5 in the future)
#   - Each appointment should be 50 minutes in duration

require 'faker';

# Doctors
Doctor.destroy_all
ActiveRecord::Base.connection.reset_pk_sequence!('doctors')

10.times do 
    Doctor.create!(name: Faker::Name.unique.name)
end

p "Created #{Doctor.count} doctors."


# Patients
Patient.destroy_all
ActiveRecord::Base.connection.reset_pk_sequence!('patients')

doctors = Doctor.all
doctors.each do |doctor|
    10.times do 
        Patient.create!(
            doctor_id: doctor.id,
            name: Faker::Name.unique.name
        )
    end
    p "Created #{doctor.patients.count} patients for doctor #{doctor.name}."
end

p "Created a total of #{Patient.count} patients."

# Appointments
Appointment.destroy_all
ActiveRecord::Base.connection.reset_pk_sequence!('appointments')

doctors.each do |doctor|
    doctor.patients.each do |patient|
        # past appointments
        5.times do
            patient.appointments.create!(
                doctor_id: doctor.id,
                patient_id: patient.id,
                start_time: Faker::Date.between(from: 1.year.ago, to: Date.today),
                duration_in_minutes: 50
            )
        end

        # future appointments
        5.times do
            patient.appointments.create!(
                doctor_id: doctor.id,
                patient_id: patient.id,
                start_time: Faker::Date.between(from: Date.today, to: 1.year.from_now),
                duration_in_minutes: 50
            )
        end
        
        p "Created #{patient.appointments.count} appointments for patient #{patient.name}."
    end
end

p "Created a total of #{Appointment.count} appointments."

