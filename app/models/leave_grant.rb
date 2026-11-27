# Lote: una carga de días. remaining_days es caché del libro; solo la tocan los
# service objects de Ledger::* dentro de la transacción que crea el movimiento.
class LeaveGrant < ApplicationRecord
  belongs_to :employee
  belongs_to :leave_type
  belongs_to :grant_batch, optional: true
  has_many :ledger_entries, dependent: :restrict_with_exception

  scope :with_remaining, -> { where("remaining_days > 0") }
  scope :valid_on, ->(date) { where("expires_on IS NULL OR expires_on > ?", date) }
  scope :for_pool, ->(pool) { joins(:leave_type).where(leave_types: { pool: pool }) }
  # FEFO: primero el lote que vence antes; los que no vencen al final.
  scope :fefo, -> { order(Arel.sql("expires_on ASC NULLS LAST, granted_on ASC, id ASC")) }

  def ledger_sum = ledger_entries.sum(:days)
  def expired?(on = Date.current) = expires_on.present? && expires_on <= on
end
