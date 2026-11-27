module Vacations
  # R2 + R3: on each anniversary, grant the 15 legal days and the progressive days.
  # Walks every pending anniversary up to `as_of` (if the job missed a day, it catches
  # up) and is idempotent per employee + anniversary number.
  class AnniversaryGrants
    Planned = Struct.new(:number, :date, :leave_type, :days, :period, :idempotency_key, :reason,
                         keyword_init: true)

    def self.call(**) = new(**).call

    # Future anniversaries (after today) up to `as_of` that the job has not granted yet.
    # Used to project balance and settlement to a future date without writing the ledger.
    def self.pending(employee:, as_of:)
      new(employee: employee, as_of: as_of).plan
        .select { |grant| grant.date > Date.current }
        .reject { |grant| LedgerEntry.exists?(idempotency_key: grant.idempotency_key) }
    end

    def initialize(employee:, as_of: Date.current)
      @employee = employee
      @as_of = as_of
    end

    def call
      plan.map do |grant|
        Ledger::Grant.call(
          employee: @employee, leave_type: grant.leave_type, days: grant.days, granted_on: grant.date,
          period: grant.period, idempotency_key: grant.idempotency_key, source: "job:anniversary",
          reason: grant.reason
        )
      end
    end

    def plan
      return [] if @employee.terminated_on.present?

      company = @employee.company
      legal = company.leave_types.find_by!(code: "legal")
      progressive = company.leave_types.find_by!(code: "progressive")

      @employee.anniversaries_between(@employee.ledger_start_on + 1, @as_of).flat_map do |number, date|
        period = "#{date.prev_year.year}-#{date.year}"
        base_key = "anniversary:employee:#{@employee.id}:n:#{number}"

        legal_days = VacationRules::Registry.resolve(:legal_days, on: date)
                                            .days(employee: @employee, anniversary_on: date)
        grants = [Planned.new(number: number, date: date, leave_type: legal, days: legal_days, period: period,
                              idempotency_key: "#{base_key}:legal",
                              reason: "#{number}° aniversario: #{legal_days} días legales")]

        progressive_rule = VacationRules::Registry.resolve(:progressive_days, on: date)
        progressive_days = progressive_rule.days(employee: @employee, anniversary_on: date)
        if progressive_days.positive?
          grants << Planned.new(
            number: number, date: date, leave_type: progressive, days: progressive_days, period: period,
            idempotency_key: "#{base_key}:progressive",
            reason: "#{number}° aniversario: #{progressive_days} días progresivos (#{progressive_rule.name.demodulize})"
          )
        end
        grants
      end
    end
  end
end
