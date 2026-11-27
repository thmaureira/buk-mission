module Ledger
  # Única puerta para cargar días: crea el lote y su movimiento en una transacción.
  # Idempotente por idempotency_key (índice único): correr dos veces no carga doble.
  class Grant
    def self.call(**) = new(**).call

    def initialize(employee:, leave_type:, days:, granted_on:, idempotency_key:, reason:, source:,
                   actor: nil, period: nil, grant_batch: nil, expires_on: :policy, kind: "grant")
      @employee = employee
      @leave_type = leave_type
      @days = BigDecimal(days.to_s)
      @granted_on = granted_on
      @idempotency_key = idempotency_key
      @reason = reason
      @source = source
      @actor = actor
      @period = period
      @grant_batch = grant_batch
      @expires_on = expires_on == :policy ? leave_type.expiration_for(granted_on) : expires_on
      @kind = kind
    end

    def call
      raise Error, "Los días a cargar deben ser mayores a 0" unless @days.positive?

      existing = LedgerEntry.find_by(idempotency_key: @idempotency_key)
      return existing.leave_grant if existing

      ActiveRecord::Base.transaction(requires_new: true) do
        grant = LeaveGrant.create!(
          employee: @employee, leave_type: @leave_type, grant_batch: @grant_batch,
          period: @period, granted_days: @days, remaining_days: @days,
          granted_on: @granted_on, expires_on: @expires_on, source: @source
        )
        LedgerEntry.create!(
          leave_grant: grant, kind: @kind, days: @days, effective_on: @granted_on,
          actor: @actor, reason: @reason, source: @source, idempotency_key: @idempotency_key
        )
        grant
      end
    rescue ActiveRecord::RecordNotUnique
      # Carrera entre dos procesos: el otro ganó; devolvemos su lote.
      LedgerEntry.find_by!(idempotency_key: @idempotency_key).leave_grant
    end
  end
end
