module VacationRules
  # PENDIENTE: no está activa (no tiene fila en rule_versions).
  # Lectura del art. 68 CT según la Dirección del Trabajo (ORD. 4492/2017): solo
  # cuentan los años con el empleador actual trabajados DESPUÉS de completar los
  # 10 años totales. Con esta lectura el ejemplo del enunciado (3 previos + 9
  # actuales) da 0 días en vez de 3.
  #
  # Si la respuesta a la consulta confirma esta lectura, se activa sin migrar datos:
  #   RuleVersion.create!(rule_key: "progressive_days",
  #                       strategy: "VacationRules::ProgressiveDaysV2",
  #                       effective_from: <fecha de vigencia>)
  # y lo ya cargado con V1 se corrige con ajustes trazables.
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
