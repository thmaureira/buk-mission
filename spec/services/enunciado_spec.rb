require "rails_helper"

# Ejemplo completo del enunciado, de punta a punta por el libro:
# 12 años y 8 meses de trabajo (9 con el empleador actual + 3 anteriores) y 24 días.
RSpec.describe "Ejemplo del enunciado" do
  let(:company) { create(:company) }
  let!(:types) { setup_types(company) }
  let(:termination_on) { Date.new(2026, 11, 26) }
  # 9 años, 8 meses y 24 días con el empleador al 26/11/2026
  let(:employee) { create(:employee, company: company, hire_date: Date.new(2017, 3, 2), prior_service_months: 36) }

  it "al 9° aniversario se cargan 15 legales + 3 progresivas = 18 días" do
    Vacations::AnniversaryGrants.call(employee: employee, as_of: termination_on)
    ninth = employee.leave_grants.where(granted_on: Date.new(2026, 3, 2))
    expect(ninth.sum(:granted_days)).to eq(18)
    expect(ninth.find_by(leave_type: types[:progressive]).granted_days).to eq(3)
  end

end
