require "rails_helper"

# The full statement example, end to end through the ledger:
# 12 years, 8 months and 24 days of work (9 years with the current employer + 3 prior).
RSpec.describe "Ejemplo del enunciado" do
  let(:company) { create(:company) }
  let!(:types) { setup_types(company) }
  let(:termination_on) { Date.new(2026, 11, 26) }
  # 9 years, 8 months and 24 days with the employer as of 26/11/2026
  let(:employee) { create(:employee, company: company, hire_date: Date.new(2017, 3, 2), prior_service_months: 36) }

  it "al 9° aniversario se cargan 15 legales + 3 progresivas = 18 días" do
    Vacations::AnniversaryGrants.call(employee: employee, as_of: termination_on)
    ninth = employee.leave_grants.where(granted_on: Date.new(2026, 3, 2))
    expect(ninth.sum(:granted_days)).to eq(18)
    expect(ninth.find_by(leave_type: types[:progressive]).granted_days).to eq(3)
  end

  it "en un finiquito a 8 meses y 24 días del último aniversario se pagan 11 días proporcionales" do
    result = Vacations::Settlement.call(employee: employee, termination_on: termination_on)
    expect([result.months, result.days]).to eq([8, 24])
    expect(result.proportional).to eq(11)
  end
end
