class ImportError < ApplicationRecord
  belongs_to :import

  validates :line_number, :message, presence: true
end
