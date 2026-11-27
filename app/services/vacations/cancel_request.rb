module Vacations
  # Anula un período aprobado revirtiendo sus usos (los días vuelven a sus lotes).
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
        Employee.lock.find(@period.employee_id) # lock por colaborador
        @period.ledger_entries.where(kind: "usage").find_each do |entry|
          Ledger::Reverse.call(entry: entry, actor: @actor, reason: "Anulación: #{@reason}")
        end
        @period.update!(status: "cancelled")
      end
    end
  end
end
