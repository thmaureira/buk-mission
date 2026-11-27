module VacationRules
  # Strategy: resuelve qué clase aplica para una regla según su fecha de vigencia.
  # Cambiar una regla = agregar una clase y una fila en rule_versions; no se migran datos.
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
