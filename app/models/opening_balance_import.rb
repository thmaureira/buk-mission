class OpeningBalanceImport < ApplicationRecord
  belongs_to :company
  belongs_to :uploaded_by, class_name: "Employee"
  belongs_to :approved_by, class_name: "Employee", optional: true
  has_many :rows, -> { order(:row_number) }, class_name: "OpeningBalanceRow", dependent: :destroy

  def pending? = status == "pending"
  def approved? = status == "approved"
  def error_rows = rows.select { |r| r.status == "error" }
  def importable_rows = rows.reject { |r| r.status == "error" }
  def status_label = { "pending" => "Pendiente de aprobación", "approved" => "Aprobada", "rejected" => "Rechazada" }[status]
end
