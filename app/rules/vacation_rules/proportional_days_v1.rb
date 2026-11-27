module VacationRules
  # Proportional vacation (settlement): 1.25 × months + 1.25 × days / 30 since the
  # last anniversary, on the 15 legal days only.
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
