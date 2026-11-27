module Ledger
  # Deducts days from lots in FEFO order (the one expiring first goes first).
  # Per-employee lock so two concurrent approvals cannot leave a negative balance.
  class Consume
    def self.call(**) = new(**).call

    def initialize(employee:, lots:, days:, on:, idempotency_prefix:, reason:, source:,
                   kind: "usage", leave_period: nil, actor: nil)
      @employee = employee
      @lots = lots
      @days = BigDecimal(days.to_s)
      @on = on
      @prefix = idempotency_prefix
      @reason = reason
      @source = source
      @kind = kind
      @leave_period = leave_period
      @actor = actor
    end

    def call
      raise Error, "Los días a descontar deben ser mayores a 0" unless @days.positive?

      ActiveRecord::Base.transaction(requires_new: true) do
        Employee.lock.find(@employee.id) # per-employee lock
        existing = LedgerEntry.where("idempotency_key LIKE ?", "#{@prefix}:%").to_a
        next existing if existing.any?

        lots = @lots.with_remaining.valid_on(@on).fefo.lock.to_a
        available = lots.sum(BigDecimal("0"), &:remaining_days)
        if available < @days
          raise InsufficientBalance,
                "Saldo insuficiente: disponible #{available.to_s('F')} días, se requieren #{@days.to_s('F')}"
        end

        left = @days
        lots.each_with_object([]) do |lot, entries|
          break entries if left.zero?

          take = [lot.remaining_days, left].min
          lot.update!(remaining_days: lot.remaining_days - take)
          entries << LedgerEntry.create!(
            leave_grant: lot, leave_period: @leave_period, kind: @kind, days: -take,
            effective_on: @on, actor: @actor, reason: @reason, source: @source,
            idempotency_key: "#{@prefix}:grant:#{lot.id}"
          )
          left -= take
        end
      end
    end
  end
end
