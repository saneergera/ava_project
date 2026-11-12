require "test_helper"

class PatientImporterTest < ActiveSupport::TestCase
  HEADER = "health identifier,health identifier province,first name,last name,middle name,phone,email," \
           "address 1,address 2,address province,address city,address postal code,date of birth,sex"

  JANE = "2,Alberta,Jane,Smith,,604-555-4567,jane.smith@example.com,456 Maple Dr,,Alberta,Edmonton,V6B 1A4,1982-07-18,F"
  JAMES = "5,British Columbia,James,Brown,,403-555-8901,james.brown@example.com,789 Pine St,,BC,Squamish,T2P 1M9,1975-11-22,M"

  # Builds CSV text from the header and the given lines, then imports it.
  def import_csv(*lines)
    content = ([ HEADER ] + lines).join("\n")
    PatientImporter.new(filename: "test.csv", content: content).call
  end

  test "importing the same file twice does not duplicate patients" do
    first = import_csv(JANE, JAMES)
    second = import_csv(JANE, JAMES)

    assert_equal 2, first.created_count
    assert_equal 0, second.created_count
    assert_equal 2, second.unchanged_count
    assert_equal 2, Patient.count
  end

  test "rejects invalid rows with a reason and still imports the valid ones" do
    bad_date = "12,Alberta,David,Thomas,,,,,,,,,1989-28-04,M"
    bad_identifier = "unknown,Alberta,John,Doe,,,,,,,,,,M"

    import = import_csv(JANE, bad_date, bad_identifier)

    assert_equal 1, import.created_count
    assert_equal 2, import.failed_count
    assert_equal 1, Patient.count

    errors = import.import_errors.order(:line_number)
    assert_equal [ 3, 4 ], errors.map(&:line_number)
    assert_match "Date of birth", errors.first.message
    assert_match "Health identifier", errors.last.message
  end

  test "updates an existing patient when a value changes" do
    import_csv(JANE)
    moved = "2,Alberta,Jane,Smith,,604-555-4567,jane.smith@example.com,99 New St,,Alberta,Calgary,T2P 1M9,1982-07-18,F"

    second = import_csv(moved)

    assert_equal 1, second.updated_count
    assert_equal 1, Patient.count
    assert_equal "99 New St", Patient.first.address_1
  end

  test "a blank value does not erase what is stored" do
    import_csv(JANE)
    without_email = "2,Alberta,Jane,Smith,,604-555-4567,,456 Maple Dr,,Alberta,Edmonton,V6B 1A4,1982-07-18,F"

    second = import_csv(without_email)

    assert_equal 1, second.unchanged_count
    assert_equal "jane.smith@example.com", Patient.first.email
  end

  test "rejects a second row for the same patient in one file" do
    jane_again = "2,AB,Jane,Smith,,,,1 Other St,,,,,,"

    import = import_csv(JANE, jane_again)

    assert_equal 1, import.created_count
    assert_equal 1, import.failed_count
    assert_match "Duplicate of line 2", import.import_errors.first.message
  end

  test "refuses a file with missing columns" do
    import = PatientImporter.new(filename: "bad.csv", content: "name,email\nJane,jane@example.com").call

    assert_equal "failed", import.status
    assert_match "Missing columns", import.failure_reason
    assert_equal 0, Patient.count
  end

  test "imports the sample file: 16 created and 4 rejected, then 16 unchanged" do
    content = file_fixture("patients.csv").read

    first = PatientImporter.new(filename: "patients.csv", content: content).call
    second = PatientImporter.new(filename: "patients.csv", content: content).call

    assert_equal 20, first.processed_count
    assert_equal 16, first.created_count
    assert_equal 4, first.failed_count
    assert_equal [ 4, 10, 19, 21 ], first.import_errors.order(:line_number).pluck(:line_number)

    assert_equal 16, second.unchanged_count
    assert_equal 4, second.failed_count
    assert_equal 16, Patient.count
  end
end
