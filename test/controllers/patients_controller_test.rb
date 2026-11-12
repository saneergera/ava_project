require "test_helper"

class PatientsControllerTest < ActionDispatch::IntegrationTest
  test "lists the patients in the database" do
    Patient.create!(health_identifier: "2", health_identifier_province: "AB", first_name: "Jane", last_name: "Smith")

    get patients_path

    assert_response :success
    assert_select "td", "Jane Smith"
    assert_select "span", "1 patient in the database"
  end
end
