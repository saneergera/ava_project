require "test_helper"


class PatientTest < ActiveSupport::TestCase
  # A valid patient with only the required fields. Each test changes one thing.
  def build_patient(changes = {})
    defaults = {
      health_identifier: "123",
      health_identifier_province: "AB",
      first_name: "Jane",
      last_name: "Smith"
    }
    Patient.new(defaults.merge(changes))
  end

  test "is valid with only the required fields" do
    assert build_patient.valid?
  end

  test "requires a health identifier made of digits" do
    assert_not build_patient(health_identifier: "").valid?
    assert_not build_patient(health_identifier: "unknown").valid?
  end

  test "cleans values when they are assigned" do
    patient = build_patient(
      health_identifier_province: "alberta",
      phone: "1-902-555-7890",
      address_postal_code: "t2p1m9",
      email: " Jane@Example.COM ",
      sex: "m"
    )

    assert_equal "AB", patient.health_identifier_province
    assert_equal "9025557890", patient.phone
    assert_equal "T2P 1M9", patient.address_postal_code
    assert_equal "jane@example.com", patient.email
    assert_equal "M", patient.sex
  end

  test "rejects malformed values" do
    assert_not build_patient(email: "jane@example.com;").valid?
    assert_not build_patient(date_of_birth: "1989-28-04").valid?
    assert_not build_patient(health_identifier_province: "Albrta").valid?
  end

  test "allows optional fields to be blank" do
    assert build_patient(email: "", phone: "", date_of_birth: "", sex: "").valid?
  end

  test "the same health identifier is one patient per province" do
    build_patient.save!

    assert_not build_patient.valid?
    assert build_patient(health_identifier_province: "BC").valid?
  end
end
