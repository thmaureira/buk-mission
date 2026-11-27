module Vacations
  # R5: days to pay in a settlement on a termination date.
  # Total = available balance + requested days not taken + proportional.
  class Settlement
    Result = Struct.new(:termination_on, :available, :requested_not_taken, :proportional,
                        :last_anniversary_on, :months, :days, :rule, keyword_init: true) do
      def total = available + requested_not_taken + proportional
    end

    def self.call(employee:, termination_on:)
      balance = Balance.new(employee, as_of: termination_on)
      rule = VacationRules::Registry.resolve(:proportional_days, on: termination_on)
      last_anniversary = employee.last_anniversary_on(termination_on)
      months, days = VacationRules::ProportionalDaysV1.elapsed(last_anniversary, termination_on)

      Result.new(
        termination_on: termination_on,
        available: balance.available("vacation"),
        requested_not_taken: balance.requested_days("vacation"),
        proportional: rule.days(employee: employee, on: termination_on),
        last_anniversary_on: last_anniversary, months: months, days: days,
        rule: rule.name.demodulize
      )
    end
  end
end
