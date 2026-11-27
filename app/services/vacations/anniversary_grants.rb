module Vacations
  # R2 + R3: en cada aniversario se cargan los 15 días legales y las progresivas.
  # Recorre todos los aniversarios pendientes hasta `as_of` (si el job no corrió un
  # día, se pone al día) y es idempotente por colaborador + n° de aniversario.
  class AnniversaryGrants
    def self.call(**) = new(**).call

    def initialize(employee:, as_of: Date.current)
      @employee = employee
      @as_of = as_of
    end

    def call
      return [] if @employee.terminated_on.present?

      company = @employee.company
      legal = company.leave_types.find_by!(code: "legal")
      progressive = company.leave_types.find_by!(code: "progressive")

      @employee.anniversaries_between(@employee.ledger_start_on + 1, @as_of).flat_map do |number, date|
        period = "#{date.prev_year.year}-#{date.year}"
        base_key = "anniversary:employee:#{@employee.id}:n:#{number}"
        grants = []

        legal_days = VacationRules::Registry.resolve(:legal_days, on: date)
                                            .days(employee: @employee, anniversary_on: date)
        grants << Ledger::Grant.call(
          employee: @employee, leave_type: legal, days: legal_days, granted_on: date, period: period,
          idempotency_key: "#{base_key}:legal", source: "job:anniversary",
          reason: "#{number}° aniversario: #{legal_days} días legales"
        )

        progressive_rule = VacationRules::Registry.resolve(:progressive_days, on: date)
        progressive_days = progressive_rule.days(employee: @employee, anniversary_on: date)
        if progressive_days.positive?
          grants << Ledger::Grant.call(
            employee: @employee, leave_type: progressive, days: progressive_days, granted_on: date,
            period: period, idempotency_key: "#{base_key}:progressive", source: "job:anniversary",
            reason: "#{number}° aniversario: #{progressive_days} días progresivos (#{progressive_rule.name.demodulize})"
          )
        end
        grants
      end
    end
  end
end
