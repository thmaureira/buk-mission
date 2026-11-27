module Vacations
  # Punto de integración con el flujo de solicitudes de Buk (fuera de scope):
  # se llama cuando una solicitud queda aprobada. Cuenta días hábiles y los
  # descuenta de los lotes; el período queda "solicitado" hasta que llega la fecha.
  class ApproveRequest
    def self.call(**) = new(**).call

    def initialize(employee:, start_date:, end_date:, approver:, pool: "vacation",
                   approved_on: Date.current, note: nil)
      @employee = employee
      @start_date = start_date
      @end_date = end_date
      @approver = approver
      @pool = pool
      @approved_on = approved_on
      @note = note
    end

    def call
      raise Ledger::Error, "Debe indicar inicio y término" if @start_date.blank? || @end_date.blank?
      raise Ledger::Error, "El término debe ser igual o posterior al inicio" if @end_date < @start_date

      days = VacationRules::Calendar.business_days(@start_date, @end_date)
      raise Ledger::Error, "El período no tiene días hábiles" if days.zero?

      ActiveRecord::Base.transaction do
        Employee.lock.find(@employee.id) # lock por colaborador
        if overlapping?
          raise Ledger::Error, "Se superpone con otro período aprobado del colaborador"
        end

        period = LeavePeriod.create!(
          employee: @employee, approver: @approver, pool: @pool,
          start_date: @start_date, end_date: @end_date, business_days: days,
          approved_at: @approved_on.in_time_zone.change(hour: 12), note: @note,
          status: @start_date <= Date.current ? "taken" : "requested"
        )
        Ledger::Consume.call(
          employee: @employee, lots: @employee.leave_grants.for_pool(@pool), days: days,
          on: @approved_on, leave_period: period, actor: @approver,
          idempotency_prefix: "usage:period:#{period.id}",
          reason: "#{LeaveType.pool_label(@pool)} del #{I18n.l(@start_date)} al #{I18n.l(@end_date)} (#{days} días hábiles)",
          source: "leave_period##{period.id}"
        )
        period
      end
    end

    private

    def overlapping?
      @employee.leave_periods.active
               .where("start_date <= ? AND end_date >= ?", @end_date, @start_date).exists?
    end
  end
end
