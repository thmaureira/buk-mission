# Append-only ledger (R9). Besides the database trigger, the model refuses to
# update or delete: corrections go through Ledger::Reverse.
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

  # For balance grouping, a reversal counts in the same bucket as the entry it reverses.
  def effective_kind = kind == "reversal" ? reverses_entry.effective_kind : kind
end
