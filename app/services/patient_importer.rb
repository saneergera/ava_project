class PatientImporter
  # csv header => patient field
  COLUMNS = {
    "health identifier" => :health_identifier,
    "health identifier province" => :health_identifier_province,
    "first name" => :first_name,
    "last name" => :last_name,
    "middle name" => :middle_name,
    "phone" => :phone,
    "email" => :email,
    "address 1" => :address_1,
    "address 2" => :address_2,
    "address province" => :address_province,
    "address city" => :address_city,
    "address postal code" => :address_postal_code,
    "date of birth" => :date_of_birth,
    "sex" => :sex
  }.freeze

  # used when the whole file can't be imported
  class FileError < StandardError; end

  def initialize(filename:, content:)
    @filename = filename
    @content = content
  end

  # Runs the import.
  #
  # Returns:
  #   Import: the saved import with its status and counts
  def call
    start_time = Time.current
    @import = Import.create!(filename: @filename)
    @counts = { created: 0, updated: 0, unchanged: 0, failed: 0 }
    @seen = {} # [province, health identifier] => line number

    begin
      read_rows.each do |row, line_number|
        result = import_row(row, line_number)
        @counts[result] += 1
      end
      @import.status = "completed"
    rescue FileError => e
      @import.status = "failed"
      @import.failure_reason = e.message
    end

    @import.update!(
      processed_count: @counts.values.sum,
      created_count: @counts[:created],
      updated_count: @counts[:updated],
      unchanged_count: @counts[:unchanged],
      failed_count: @counts[:failed],
      duration_ms: ((Time.current - start_time) * 1000).round
    )
    @import
  end

  private

  # Reads the csv and checks the file is ok.
  #
  # Returns:
  #   Array: pairs of [row, line_number], empty lines skipped
  #
  # Raises:
  #   FileError: if the file is empty, not UTF-8, not a csv,
  #   missing columns or has no patients
  def read_rows
    text = @content.to_s.dup.force_encoding("UTF-8").delete_prefix("﻿")
    raise FileError, "The file is not valid UTF-8 text" unless text.valid_encoding?
    raise FileError, "The file is empty" if text.strip.empty?

    csv = CSV.new(text, headers: true, header_converters: ->(header) { header.to_s.strip.downcase })

    rows = []
    csv.each do |row|
      next if row.fields.all?(&:blank?)

      rows << [ row, csv.lineno ]
    end

    missing = COLUMNS.keys - csv.headers
    raise FileError, "Missing columns: #{missing.join(', ')}" if missing.any?
    raise FileError, "The file has no patient rows" if rows.empty?

    rows
  rescue CSV::MalformedCSVError
    raise FileError, "The file is not a readable CSV"
  end

  # Saves one row as a patient, or updates the patient if they already exist.
  #
  # Returns:
  #   Symbol: :created, :updated, :unchanged or :failed
  def import_row(row, line_number)
    attributes = attributes_from(row)

    patient = Patient.find_or_initialize_by(
      health_identifier_province: attributes[:health_identifier_province],
      health_identifier: attributes[:health_identifier]
    )
    patient.assign_attributes(attributes)

    return reject(line_number, patient.errors.full_messages) unless patient.valid?

    key = [ patient.health_identifier_province, patient.health_identifier ]
    if @seen[key]
      return reject(line_number, [ "Duplicate of line #{@seen[key]}: same province and health identifier" ])
    end
    @seen[key] = line_number

    if patient.new_record?
      patient.save!
      :created
    elsif patient.changed?
      patient.save!
      :updated
    else
      :unchanged
    end
  rescue ActiveRecord::RecordNotUnique
    # another upload saved the same patient at the same time
    reject(line_number, [ "Patient was being imported by another upload; upload the file again" ])
  end

  # Turns a csv row into a hash of patient fields.
  # Blank values are skipped so they don't wipe out saved data.
  def attributes_from(row)
    attributes = {}
    COLUMNS.each do |header, field|
      value = row[header]
      attributes[field] = value if value.present?
    end
    attributes
  end

  # Saves the error messages for a line and returns :failed.
  # Only the message is saved, not the patient data.
  def reject(line_number, messages)
    messages.each do |message|
      @import.import_errors.create!(line_number: line_number, message: message)
    end
    :failed
  end
end
