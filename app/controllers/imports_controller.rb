# The three screens: upload a CSV, migration history, migration details.
# The import itself is done by PatientImporter.
class ImportsController < ApplicationController
  MAX_FILE_SIZE = 5.megabytes

  # Migration history
  def index
    @imports = Import.order(created_at: :desc)
  end

  # Upload page
  def new
  end

  # Runs the import, then shows its details
  def create
    file = params[:file]

    if file.blank?
      redirect_to new_import_path, alert: "Choose a CSV file first."
    elsif file.size > MAX_FILE_SIZE
      redirect_to new_import_path, alert: "The file is too large (the limit is 5 MB)."
    else
      import = PatientImporter.new(filename: file.original_filename, content: file.read).call
      redirect_to import_path(import)
    end
  end

  # Migration details
  def show
    @import = Import.find(params[:id])
    @errors = @import.import_errors.order(:line_number, :id)
  end
end
