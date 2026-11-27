module VacationRules
  # Labour Code Art. 67: 15 business days per year of service.
  class LegalDaysV1
    DAYS = 15

    def self.days(employee:, anniversary_on:) = DAYS
  end
end
