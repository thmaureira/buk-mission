module Vacations
  # R10: grants a configurable type to one person or a group, with a reason.
  class BulkGrant
    def self.call(**) = new(**).call

    def initialize(leave_type:, employees:, days:, granted_on:, reason:, actor:, target_description: nil)
      @leave_type = leave_type
      @employees = employees
      @days = days
      @granted_on = granted_on
      @reason = reason
      @actor = actor
      @target_description = target_description
    end

    def call
      raise Ledger::Error, "Debe indicar un motivo" if @reason.blank?
      raise Ledger::Error, "Debe seleccionar al menos un colaborador" if @employees.empty?

      ActiveRecord::Base.transaction do
        batch = GrantBatch.create!(
          company: @leave_type.company, leave_type: @leave_type, created_by: @actor,
          days: @days, granted_on: @granted_on, reason: @reason, target_description: @target_description
        )
        @employees.each do |employee|
          Ledger::Grant.call(
            employee: employee, leave_type: @leave_type, days: @days, granted_on: @granted_on,
            period: @granted_on.year.to_s, grant_batch: batch, actor: @actor, reason: @reason,
            source: "grant_batch##{batch.id}", idempotency_key: "batch:#{batch.id}:employee:#{employee.id}"
          )
        end
        batch
      end
    end
  end
end
