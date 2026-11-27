module Vacations
  # Cancels an approved period by reversing its usages (the days return to their lots).
  class CancelRequest
    def self.call(**) = new(**).call

    def initialize(leave_period:, actor:, reason:)
      @period = leave_period
      @actor = actor
      @reason = reason
    end

    def call
      raise Ledger::Error, "El período ya está anulado" if @period.cancelled?
      raise Ledger::Error, "Debe indicar un motivo" if @reason.blank?

      ActiveRecord::Base.transaction do
        Employee.lock.find(@period.employee_id) # per-employee lock
        @period.ledger_entries.where(kind: "usage").find_each do |entry|
          Ledger::Reverse.call(entry: entry, actor: @actor, reason: "Anulación: #{@reason}")
        end
        @period.update!(status: "cancelled")
      end
    end
  end
end
