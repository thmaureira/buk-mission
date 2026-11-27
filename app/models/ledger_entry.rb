# Libro de solo inserción (R9). Además del trigger en la base, el modelo se niega
# a actualizar o borrar: para corregir se usa Ledger::Reverse.
class LedgerEntry < ApplicationRecord
  KINDS = %w[grant usage expiration adjustment reversal].freeze
  KIND_LABELS = {
    "grant" => "Carga", "usage" => "Uso", "expiration" => "Vencimiento",
    "adjustment" => "Ajuste", "reversal" => "Reverso"
  }.freeze

  belongs_to :leave_grant
  belongs_to :leave_period, optional: true
  belongs_to :actor, class_name: "Employee", optional: true
  belongs_to :reverses_entry, class_name: "LedgerEntry", optional: true
  has_one :reversal, class_name: "LedgerEntry", foreign_key: :reverses_entry_id, inverse_of: :reverses_entry

  validates :kind, inclusion: { in: KINDS }
  validates :days, numericality: { other_than: 0 }
  validates :reason, :source, :idempotency_key, :effective_on, presence: true

  scope :chronological, -> { order(:effective_on, :id) }

  def readonly? = persisted?
  before_destroy { raise ActiveRecord::ReadOnlyRecord, "ledger_entries es solo inserción" }

  def kind_label = KIND_LABELS.fetch(kind)
  def actor_name = actor&.name || "Sistema"
  def reversible? = kind != "reversal" && reversal.nil?

  # Para agrupar en el saldo, un reverso cuenta en el mismo balde que lo revertido.
  def effective_kind = kind == "reversal" ? reverses_entry.effective_kind : kind
end
