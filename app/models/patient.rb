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

  # The shape each value must have after it has been cleaned.
  DIGITS_ONLY = /\A\d+\z/
  PHONE = /\A\d{10}\z/
  EMAIL = /\A[^@\s;,]+@[^@\s;,]+\.[^@\s;,]+\z/
  POSTAL_CODE = /\A[A-Z]\d[A-Z] \d[A-Z]\d\z/
  DATE_FORMAT = /\A\d{4}-\d{2}-\d{2}\z/

  # Trim spaces and save empty strings as nil.
  normalizes :health_identifier, :first_name, :last_name, :middle_name,
             :address_1, :address_2, :address_city,
             with: ->(value) { value.strip.presence }

  normalizes :health_identifier_province, :address_province,
             with: ->(value) { Patient.province_code(value) }

  normalizes :sex, with: ->(value) { value.strip.upcase.presence }
  normalizes :email, with: ->(value) { value.strip.downcase.presence }
  normalizes :phone, with: ->(value) { Patient.clean_phone(value) }
  normalizes :address_postal_code, with: ->(value) { Patient.clean_postal_code(value) }

  validates :health_identifier, :health_identifier_province, :first_name, :last_name,
            presence: true

  validates :health_identifier,
            format: { with: DIGITS_ONLY, message: "must contain only digits" },
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
            format: { with: EMAIL, message: "is not a valid email address" },
            allow_blank: true

  validates :phone,
            format: { with: PHONE, message: "must have 10 digits" },
            allow_blank: true

  validates :address_postal_code,
            format: { with: POSTAL_CODE, message: "is not a valid Canadian postal code" },
            allow_blank: true

  validate :date_of_birth_must_be_real

  # Turns a province name or code into the 2 letter code, so "alberta"
  # and "ab" both become "AB". An unknown province is returned as it was
  # given, so the validation rejects it.
  def self.province_code(value)
    text = value.strip
    return nil if text.empty?

    PROVINCES.each do |code, name|
      return code if text.casecmp?(code) || text.casecmp?(name)
    end

    text
  end

  # Keeps only the digits of a phone number, so "1-902-555-7890" and
  # "(902) 555-7890" both become "9025557890". Anything that isn't
  # 10 digits is returned as it was given, so the validation rejects it.
  def self.clean_phone(value)
    text = value.strip
    return nil if text.empty?

    digits = text.gsub(/\D/, "")
    digits = digits.delete_prefix("1") if digits.length == 11

    if digits.length == 10
      digits
    else
      text
    end
  end

  # Formats a postal code like "T2P 1M9": no extra spaces, upper case,
  # one space after the third character.
  def self.clean_postal_code(value)
    compact = value.gsub(/\s/, "").upcase
    return nil if compact.empty?

    "#{compact[0, 3]} #{compact[3..]}"
  end

  private

  # Makes sure date of birth is a real date and not in the future.
  # The value is checked as it was given, because Rails turns a bad
  # date like "1989-28-04" into nil without telling us.
  def date_of_birth_must_be_real
    given = date_of_birth_before_type_cast.to_s.strip
    return if given.empty?

    if !given.match?(DATE_FORMAT) || date_of_birth.nil?
      errors.add(:date_of_birth, "is not a valid date (expected YYYY-MM-DD)")
    elsif date_of_birth > Date.current
      errors.add(:date_of_birth, "cannot be in the future")
    end
  end
end
