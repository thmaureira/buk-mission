module VacationRules
  # Active rule: the one in the mission statement. If on the anniversary the employee
  # has 10+ years of work (accredited prior years, capped at 10, + current ones) and at
  # least 3 continuous years with the current employer, they get 1 day for every 3
  # years completed with the current employer (3rd, 6th, 9th year...).
  #
  # Statement example: 3 prior years + 9 current = 12 ≥ 10 → 9 / 3 = 3 days
  # → 15 + 3 = 18 days.
  #
  # The Labour Directorate reading of Art. 68 lives in ProgressiveDaysV2, inactive
  # until the open question is answered.
  class ProgressiveDaysV1
    MAX_PRIOR_YEARS = 10
    THRESHOLD_YEARS = 10
    YEARS_PER_DAY = 3

    def self.days(employee:, anniversary_on:)
      calculate(prior_service_months: employee.prior_service_months,
                current_years: employee.years_of_service(on: anniversary_on))
    end

    # Pure function: easy to test with the statement's cases.
    def self.calculate(prior_service_months:, current_years:)
      prior_years = [prior_service_months.to_i / 12, MAX_PRIOR_YEARS].min
      return 0 if prior_years + current_years < THRESHOLD_YEARS
      return 0 if current_years < YEARS_PER_DAY

      current_years / YEARS_PER_DAY
    end
  end
end
