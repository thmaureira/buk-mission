module VacationRules
  # Business days: Monday to Friday, minus national holidays (holidays table).
  class Calendar
    def self.business_days(from, to)
      return 0 if from.nil? || to.nil? || to < from

      holidays = Holiday.national.where(date: from..to).pluck(:date).to_set
      (from..to).count { |d| !d.saturday? && !d.sunday? && !holidays.include?(d) }
    end
  end
end
