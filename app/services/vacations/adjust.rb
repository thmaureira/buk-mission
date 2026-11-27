module Vacations
  # Manual HR adjustment on a type. Positive: creates a lot; negative: deducts from
  # that type's lots (FEFO). The form token makes the submission idempotent.
  class Adjust
    def self.call(**) = new(**).call

    def initialize(employee:, leave_type:, days:, reason:, actor:, token:, on: Date.current)
      @employee = employee
      @leave_type = leave_type
      @days = BigDecimal(days.to_s)
      @reason = reason
      @actor = actor
      @token = token
      @on = on
    end

    def call
      raise Ledger::Error, "Debe indicar un motivo" if @reason.blank?
      raise Ledger::Error, "Los días no pueden ser 0" if @days.zero?

      if @days.positive?
        Ledger::Grant.call(
          employee: @employee, leave_type: @leave_type, days: @days, granted_on: @on, kind: "adjustment",
          actor: @actor, reason: @reason, source: "manual_adjustment", period: @on.year.to_s,
          idempotency_key: "adjustment:#{@token}"
        )
      else
        Ledger::Consume.call(
          employee: @employee, lots: @employee.leave_grants.where(leave_type: @leave_type),
          days: -@days, on: @on, kind: "adjustment", actor: @actor, reason: @reason,
          source: "manual_adjustment", idempotency_prefix: "adjustment:#{@token}"
        )
      end
    end
  end
end
