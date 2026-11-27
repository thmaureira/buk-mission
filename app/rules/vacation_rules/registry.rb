module VacationRules
  # Strategy: resolves which class applies to a rule by its effective date.
  # Changing a rule = adding a class and a rule_versions row; no data migration.
  class Registry
    DEFAULTS = {
      "legal_days" => "VacationRules::LegalDaysV1",
      "progressive_days" => "VacationRules::ProgressiveDaysV1",
      "proportional_days" => "VacationRules::ProportionalDaysV1"
    }.freeze

    def self.resolve(rule_key, on:, country: "CL")
      version = RuleVersion.where(country: country, rule_key: rule_key.to_s)
                           .where("effective_from <= ?", on)
                           .order(effective_from: :desc).first
      (version&.strategy || DEFAULTS.fetch(rule_key.to_s)).constantize
    end
  end
end
