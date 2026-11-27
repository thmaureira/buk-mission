require "rails_helper"

RSpec.describe "Reglas legales (Strategy, funciones puras)" do
  describe VacationRules::ProgressiveDaysV1 do
    it "caso del enunciado: 3 años previos + 9 con el empleador actual = 3 progresivos (18 días en total)" do
      progressive = described_class.calculate(prior_service_months: 36, current_years: 9)
      expect(progressive).to eq(3)
      expect(VacationRules::LegalDaysV1::DAYS + progressive).to eq(18)
    end

    it "suma 1 día al 3°, 6° y 9° año con el empleador si hay 10+ años totales" do
      expect(described_class.calculate(prior_service_months: 120, current_years: 2)).to eq(0) # < 3 continuos
      expect(described_class.calculate(prior_service_months: 120, current_years: 3)).to eq(1)
      expect(described_class.calculate(prior_service_months: 120, current_years: 6)).to eq(2)
    end

    it "no aplica si no se llega a 10 años totales" do
      expect(described_class.calculate(prior_service_months: 36, current_years: 6)).to eq(0)  # 9 años
      expect(described_class.calculate(prior_service_months: 36, current_years: 7)).to eq(2)  # 10 años
    end

    it "topa la antigüedad previa en 10 años y usa la parte entera de meses / 12" do
      expect(described_class.calculate(prior_service_months: 240, current_years: 3)).to eq(1)
      expect(described_class.calculate(prior_service_months: 35, current_years: 7)).to eq(0) # 2 años previos → 9
    end
  end

  describe VacationRules::ProportionalDaysV1 do
    it "caso del enunciado: 8 meses y 24 días = 11 días" do
      expect(described_class.calculate(months: 8, days: 24)).to eq(11)
    end

    it "calcula desde el último aniversario" do
      employee = build(:employee, hire_date: Date.new(2026, 3, 2))
      expect(described_class.days(employee: employee, on: Date.new(2026, 11, 26))).to eq(11)
    end

    it "mide meses y días transcurridos" do
      expect(described_class.elapsed(Date.new(2026, 1, 31), Date.new(2026, 3, 1))).to eq([1, 1])
    end
  end

  describe VacationRules::Calendar do
    it "cuenta solo lunes a viernes sin feriados" do
      Holiday.create!(date: Date.new(2026, 12, 25), name: "Navidad")
      # 21 al 30 de diciembre de 2026: 8 días de semana, menos Navidad
      expect(described_class.business_days(Date.new(2026, 12, 21), Date.new(2026, 12, 30))).to eq(7)
    end
  end

  describe VacationRules::Registry do
    it "elige la versión vigente a la fecha" do
      stub_const("VacationRules::LegalDaysV2", Class.new { def self.days(**) = 20 })
      RuleVersion.create!(rule_key: "legal_days", strategy: "VacationRules::LegalDaysV2", effective_from: Date.new(2027, 1, 1))
      expect(described_class.resolve(:legal_days, on: Date.new(2026, 12, 31))).to eq(VacationRules::LegalDaysV1)
      expect(described_class.resolve(:legal_days, on: Date.new(2027, 1, 1))).to eq(VacationRules::LegalDaysV2)
    end
  end
end
