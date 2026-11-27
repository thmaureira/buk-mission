class LeavePeriod < ApplicationRecord
  STATUSES = %w[requested taken cancelled].freeze

  belongs_to :employee
  belongs_to :approver, class_name: "Employee"
  has_many :ledger_entries, dependent: :restrict_with_exception

  validates :start_date, :end_date, :business_days, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :end_after_start

  scope :active, -> { where.not(status: "cancelled") }
  scope :chronological, -> { order(start_date: :desc) }

  def cancelled? = status == "cancelled"

  # Estado a una fecha dada (la vista permite consultar el saldo a cualquier fecha).
  def status_on(date)
    return "cancelled" if cancelled?
    start_date <= date ? "taken" : "requested"
  end

  def status_label(date = Date.current)
    { "requested" => "Solicitada", "taken" => "Tomada", "cancelled" => "Anulada" }[status_on(date)]
  end

  private

  def end_after_start
    errors.add(:end_date, "debe ser igual o posterior al inicio") if start_date && end_date && end_date < start_date
  end
end
