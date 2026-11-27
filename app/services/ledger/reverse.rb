module Ledger
  # Correction: adds an opposite entry. Nothing is deleted or edited (R9).
  class Reverse
    def self.call(**) = new(**).call

    def initialize(entry:, actor:, reason:, on: Date.current)
      @entry = entry
      @actor = actor
      @reason = reason
      @on = on
    end

    def call
      raise Error, "Debe indicar un motivo" if @reason.blank?

      ActiveRecord::Base.transaction(requires_new: true) do
        grant = @entry.leave_grant.lock!
        @entry.reload
        raise NotReversible, "El movimiento ya fue revertido o es un reverso" unless @entry.reversible?

        new_remaining = grant.remaining_days - @entry.days
        if new_remaining.negative?
          raise NotReversible, "No se puede revertir: ya se usaron días de este lote. Revierta primero esos usos."
        end

        reversal = LedgerEntry.create!(
          leave_grant: grant, leave_period: @entry.leave_period, reverses_entry: @entry,
          kind: "reversal", days: -@entry.days, effective_on: @on, actor: @actor,
          reason: @reason, source: "reversal_of##{@entry.id}", idempotency_key: "reverse:entry:#{@entry.id}"
        )
        grant.update!(remaining_days: new_remaining)
        reversal
      end
    end
  end
end
