require "test_helper"

class ImportsControllerTest < ActionDispatch::IntegrationTest
  test "uploading the sample file imports it and shows the details" do
    file = fixture_file_upload("patients.csv", "text/csv")

    post imports_path, params: { file: file }
    follow_redirect!

    assert_response :success
    assert_equal 16, Patient.count
    assert_select "h1", "Migration details"
    assert_select "td", "Email is not a valid email address"
  end

  test "submitting without a file goes back to the upload page" do
    post imports_path

    assert_redirected_to new_import_path
    assert_equal 0, Import.count
  end

  test "the history lists previous uploads" do
    Import.create!(filename: "january.csv", status: "completed")

    get imports_path

    assert_response :success
    assert_select "td", "january.csv"
  end
end
