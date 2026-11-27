module VacationRules
  # Art. 67 CT: 15 días hábiles por cada año de servicio.
  class LegalDaysV1
    DAYS = 15

    def self.days(employee:, anniversary_on:) = DAYS
  end
end
