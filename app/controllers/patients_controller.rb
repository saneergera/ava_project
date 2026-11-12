# Read-only list of the patients that have been imported.
class PatientsController < ApplicationController
  def index
    @patients = Patient.order(:last_name, :first_name)
  end
end
