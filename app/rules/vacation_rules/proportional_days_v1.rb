module VacationRules
  # Feriado proporcional (finiquito): 1,25 × meses + 1,25 × días / 30 desde el
  # último aniversario, solo sobre los 15 días legales.
  class ProportionalDaysV1
    DAYS_PER_MONTH = BigDecimal("1.25")

    def self.days(employee:, on:)
      from = employee.last_anniversary_on(on)
      months, days = elapsed(from, on)
      calculate(months: months, days: days)
    end

    def self.calculate(months:, days:)
      (DAYS_PER_MONTH * months + DAYS_PER_MONTH * days / 30).round(2)
    end

    def self.elapsed(from, to)
      months = (to.year * 12 + to.month) - (from.year * 12 + from.month)
      months -= 1 if (from >> months) > to
      [months, (to - (from >> months)).to_i]
    end
  end
end
