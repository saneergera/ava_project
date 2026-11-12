# Stores patient info. Values get cleaned up when they're set
# and checked before saving.
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

  POSTAL_CODE = /\A[A-Z]\d[A-Z] \d[A-Z]\d\z/
  DATE_FORMAT = /\A\d{4}-\d{2}-\d{2}\z/

  # trim spaces, save empty strings as nil
  normalizes :health_identifier, :first_name, :last_name, :middle_name,
             :address_1, :address_2, :address_city,
             with: ->(value) { value.strip.presence }

  normalizes :health_identifier_province, :address_province,
             with: ->(value) { Patient.province_code(value) }

  normalizes :sex,   with: ->(value) { value.strip.upcase.presence }
  normalizes :email, with: ->(value) { value.strip.downcase.presence }
  normalizes :phone, with: ->(value) { Patient.clean_phone(value) }
  normalizes :address_postal_code, with: ->(value) { Patient.clean_postal_code(value) }

  validates :health_identifier, :health_identifier_province, :first_name, :last_name,
            presence: true

  validates :health_identifier,
            format: { with: /\A\d+\z/, message: "must contain only digits" },
            uniqueness: { scope: :health_identifier_province,
                          message: "already exists for this province" },
            allow_blank: true

  validates :health_identifier_province, :address_province,
            inclusion: { in: PROVINCES.keys, message: "is not a Canadian province or territory" },
            allow_blank: true

  validates :sex,
            inclusion: { in: SEXES, message: "must be M, F, NB or U" },
            allow_blank: true

  validates :email,
            format: { with: /\A[^@\s;,]+@[^@\s;,]+\.[^@\s;,]+\z/,
                      message: "is not a valid email address" },
            allow_blank: true

  validates :phone,
            format: { with: /\A\d{10}\z/, message: "must have 10 digits" },
            allow_blank: true

  validates :address_postal_code,
            format: { with: POSTAL_CODE, message: "is not a valid Canadian postal code" },
            allow_blank: true

  validate :date_of_birth_must_be_real

  # Gets the 2 letter province code from a name or code.
  #
  # Args:
  #   value (String): province name or code, like "alberta" or "AB"
  #
  # Returns:
  #   String: the code, like "AB". If we don't know the province we
  #   just return what was given so the validation catches it.
  def self.province_code(value)
    text = value.strip.squeeze(" ")
    return nil if text.empty?

    match = PROVINCES.find { |code, name| text.casecmp?(code) || text.casecmp?(name) }
    match ? match.first : text
  end

  # Keeps only the digits of a phone number.
  # "1-902-555-7890" and "(902) 555-7890" both become "9025557890".
  #
  # Args:
  #   value (String): the phone number
  #
  # Returns:
  #   String: 10 digits, or the original text if it isn't 10 digits
  def self.clean_phone(value)
    text = value.strip
    return nil if text.empty?

    digits = text.gsub(/\D/, "")
    digits = digits.delete_prefix("1") if digits.length == 11

    digits.length == 10 ? digits : text
  end

  # Formats a postal code like "T2P 1M9".
  #
  # Args:
  #   value (String): the postal code, like "t2p1m9"
  #
  # Returns:
  #   String: the formatted code, or the original text if it's not valid
  def self.clean_postal_code(value)
    text = value.strip
    return nil if text.empty?

    compact = text.gsub(/\s/, "").upcase
    return text unless compact.match?(/\A[A-Z]\d[A-Z]\d[A-Z]\d\z/)

    "#{compact[0, 3]} #{compact[3, 3]}"
  end

  private

  # Makes sure date of birth is a real date and not in the future.
  # Have to check the raw value because Rails turns bad dates
  # like "1989-28-04" into nil without telling us.
  def date_of_birth_must_be_real
    raw = date_of_birth_before_type_cast
    return if raw.blank?

    if raw.is_a?(String) && (!raw.strip.match?(DATE_FORMAT) || date_of_birth.nil?)
      errors.add(:date_of_birth, "is not a valid date (expected YYYY-MM-DD)")
    elsif date_of_birth && date_of_birth > Date.current
      errors.add(:date_of_birth, "cannot be in the future")
    end
  end
end
