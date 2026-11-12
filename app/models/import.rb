class Import < ApplicationRecord
  STATUSES = %w[processing completed failed].freeze

  has_many :import_errors, dependent: :destroy

  validates :filename, presence: true
  validates :status, inclusion: { in: STATUSES }
end
