module VacationRules
  # Regla activa: la del enunciado. Si al aniversario el colaborador suma 10+ años
  # de trabajo (previos acreditados, tope 10, + actuales) y lleva al menos 3 años
  # continuos con el empleador actual, recibe 1 día por cada 3 años cumplidos con
  # el empleador actual (3°, 6°, 9° año...).
  #
  # Ejemplo del enunciado: 3 años previos + 9 actuales = 12 ≥ 10 → 9 / 3 = 3 días
  # → 15 + 3 = 18 días.
  #
  # La lectura del art. 68 según la Dirección del Trabajo queda como
  # ProgressiveDaysV2, sin activar, a la espera de la respuesta a la consulta.
  class ProgressiveDaysV1
    MAX_PRIOR_YEARS = 10
    THRESHOLD_YEARS = 10
    YEARS_PER_DAY = 3

    def self.days(employee:, anniversary_on:)
      calculate(prior_service_months: employee.prior_service_months,
                current_years: employee.years_of_service(on: anniversary_on))
    end

    # Función pura: fácil de testear con los casos del enunciado.
    def self.calculate(prior_service_months:, current_years:)
      prior_years = [prior_service_months.to_i / 12, MAX_PRIOR_YEARS].min
      return 0 if prior_years + current_years < THRESHOLD_YEARS
      return 0 if current_years < YEARS_PER_DAY

      current_years / YEARS_PER_DAY
    end
  end
end
