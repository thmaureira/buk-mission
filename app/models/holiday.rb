class Holiday < ApplicationRecord
  validates :date, :name, presence: true
  scope :national, -> { where(scope: "national") }
end
