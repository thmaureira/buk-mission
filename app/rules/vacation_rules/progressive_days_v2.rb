module VacationRules
  # PENDING: not active (no row in rule_versions).
  # Labour Directorate reading of Labour Code Art. 68 (ORD. 4492/2017): only years
  # with the current employer worked AFTER reaching 10 total years count. With this
  # reading the statement example (3 prior + 9 current) gives 0 days instead of 3.
  #
  # If the answer confirms this reading, activate it without migrating data:
  #   RuleVersion.create!(rule_key: "progressive_days",
  #                       strategy: "VacationRules::ProgressiveDaysV2",
  #                       effective_from: <effective date>)
  # and fix what V1 already granted with traceable adjustments.
  class ProgressiveDaysV2
    def self.days(employee:, anniversary_on:)
      calculate(prior_service_months: employee.prior_service_months,
                current_years: employee.years_of_service(on: anniversary_on))
    end

    def self.calculate(prior_service_months:, current_years:)
      prior_years = [prior_service_months.to_i / 12, ProgressiveDaysV1::MAX_PRIOR_YEARS].min
      years_to_threshold = [ProgressiveDaysV1::THRESHOLD_YEARS - prior_years, 0].max
      new_years = current_years - years_to_threshold
      return 0 if new_years < ProgressiveDaysV1::YEARS_PER_DAY

      new_years / ProgressiveDaysV1::YEARS_PER_DAY
    end
  end
end
