class Patient < ApplicationRecord
  PROVINCES = {
    "AB" => "Alberta",
    "BC" => "British Columbia",
    "MB" => "Manitoba",
    "NB" => "New Brunswick",
    "NL" => "Newfoundland and Labrador",
    "NS" => "Nova Scotia",
    "NT" => "Northwest Territories",
    "NU" => "Nunavut",
    "ON" => "Ontario",
    "PE" => "Prince Edward Island",
    "QC" => "Quebec",
    "SK" => "Saskatchewan",
    "YT" => "Yukon"
  }.freeze

  SEXES = %w[M F NB U].freeze

  normalizes :health_identifier, :first_name, :last_name, :middle_name,
             :address_1, :address_2, :address_city,
             with: ->(value) { value.strip.presence }

  normalizes :health_identifier_province, :address_province,
              with: ->(value) { Patient.province_code(value) }

  def self.province_code(value)
    text = value.strip.squeeze(" ")
    nil if text.empty?

    PROVINCES.each do |code, name|
      return code if text.casecmp?(code) || text.casecmp?(name)
    end
    text
  end
end
